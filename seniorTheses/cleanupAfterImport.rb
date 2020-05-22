#!/usr/bin/env jruby
require 'lumberjack'
require 'cli/dconstants'

$root = DConstants::SENIOR_THESIS_HANDLE
$year = DConstants::DEFAULT_YEAR
$year_metadata_field = "pu.date.classyear"
$account = DConstants::LOGIN

require 'dspace'
require 'cli/ditem'

DSpace.load
DSpace.login($account)
java_import org.dspace.core.Constants

# get first part of collection name
def shortCollectionName(c)
  c.getName.split(',')[0].strip()
end

# get all senior thesis items in given year
def getClassYearItems()
  items = DSpace.findByMetadataValue($year_metadata_field, $year, nil)
  $logger.info "Select #{$year_metadata_field}=#{$year} in #{$root}  found #{items.length} items"
  return items
end

# Use Lumberjack to set a log_file
def setLogger(log_file, level = :info)
  $logger = Lumberjack::Logger.new("#{log_file}", :buffer_size => 0) # Open a new log file with INFO level
  $logger.level = level
  puts "#{level} logging to  #{log_file}"
end

# clear metadata for senior thesis items with a null abstract
def fixNullAbstract()
  setLogger("#{ENV['DSPACE_HOME']}/log/fixNullAbstract.log")
  items = DSpace.findByMetadataValue('dc.description.abstract', 'null', nil)
  nupdate = 0
  nerror = 0
  items.each do |i|
    begin
      if (i.archived? and i.getParentObject.getParentObject.getHandle == $root) then
        # its in a collection inside root (senior thesis)
        # check that there is exactly one abstract  - jyst to be anal
        if (i.getMetadata('dc', 'description', 'abstract', nil, "*").length > 1) then
          $logger.warn "MULTIPLE dc.description.abstract values for #{i.getHandle()} in #{i.getParentObject.getParentObject.getName}"
        else
          $logger.info("clear dc.description.abstract=null for #{i.getHandle()} in #{i.getParentObject.getParentObject.getName}")
          i.clearMetadata('dc', 'description', 'abstract', '*')
          i.update
          DSpace.create(i).index(true)
          nupdate += 1
        end
      end
    rescue Exception => e
      $logger.error "exception when processing item #{i.to_s}"
      $logger.error e.inspect
      nerror += 1
    end
  end
  $logger.info("SUMMARY clear abstract in  #{nupdate} items")
  $logger.info("SUMMARY errors #{nerror} ")
end


# for all items in the class $year:
# compare the pu.department metadata value with the name of the owning collection
# the values should match (minus the year info on the collection name)
def compareDepartmentMetadataWithOwningCollection(fix)
  setLogger("#{ENV['DSPACE_HOME']}/log/compareDepartmentWithCollectionName.log")

  collections = DSpace.fromString($root).collections

# colmap - maps shortened collection's name to collection pointers
  colmap = {}; collections.each {|c| colmap[shortCollectionName(c)] = c}
#
# go over all archived items with the given year_metadata_field equal to year
  items = getClassYearItems()

  mismatch = 0
  nerror = 0
  multival = 0
  items.each do |i|
    begin
      if i.archived? then
        ownerName = shortCollectionName(i.getOwningCollection)

        vals = i.getMetadata("pu", "department", nil, "*")
        if (vals.length > 1) then
          $logger.warn("ITEM #{i.getHandle}: MULTIPLE pu.department values; checking first only")
          multival = multival + 1
        end
        val = vals[0]
        if ownerName == val.value then
          $logger.info("ITEM #{i.getHandle}: pu.department='#{val.value}' matches collection '#{ownerName}'")
        else
          mismatch = mismatch +1
          $logger.info("ITEM #{i.getHandle}: pu.department='#{val.value}' DOES NOT match collection '#{ownerName}'")
          if (fix) then
            if (vals.length == 1) then
              i.setMetadataSingleValue('pu', "department", nil, '*', ownerName);
              i.update()
              $logger.info("ITEM #{i.getHandle}: pu.department='#{val.value}' FIXED to match collection '#{ownerName}'")
            else
              $logger.error("ITEM #{i.getHandle}: pu.department='#{val.value}' has other values NOT FIXING")
            end
          end
        end
      end
    end
  end
  $logger.info("SUMMARY items with multiple department values #{multival}")
  $logger.info("SUMMARY mismatches #{mismatch} ")
  $logger.info("SUMMARY errors #{nerror} ")
end

# Add theses to their certificate program collections
def mapToCollectionBasedOncertificateProgram()
  setLogger("#{ENV['DSPACE_HOME']}/log/mapToCollectionBasedOncertificateProgram.log")

# colmap - maps shortened collection's name to collection pointers
  colmap = {}; DSpace.fromString($root).collections.each {|c| colmap[shortCollectionName(c)] = c}

# go over all archived items with the given year_metadata_value equal to $year
# and map to collections defined in pu.certificate metadata field
  nitems, narchived, nmapped, nerror = 0, 0, 0, 0;
  items = getClassYearItems
  items.each do |i|
      begin
        nitems += 1
        if i.archived? then
          # add i to all collections indicated in its pu.department value IF collection is not already in that collection
          narchived += 1
          owners = i.getCollections
          $logger.debug "#{i.to_s}  in #{owners.collect {|o| o.getName}.inspect}"
          i.getMetadata("pu", "certificate", nil, "*").each do |val|
            map_to_col = colmap[val.value]
            if (map_to_col) then
              if owners.include? map_to_col then
                $logger.info("ITEM #{i.getHandle}: already in '#{map_to_col.getName}'")
              else
                $logger.info("ITEM #{i.getHandle}: mapping to '#{map_to_col.getName}'")
                map_to_col.addItem(i)
                DSpace.create(i).index(true)
                nmapped += 1
              end
            else
              $logger.error("ITEM #{i.getHandle}: could not find collection with name '#{val.value}'")
              nerror += 1
            end
          end
        end
      rescue Exception => e
        $logger.error "exception when processing item #{i.to_s}"
        $logger.error e.inspect
        nerror += 1
      end
  end
  $logger.info("SUMMARY processed #{narchived} items out of #{nitems} items")
  $logger.info("SUMMARY added #{nmapped} collection mappings")
  $logger.info("SUMMARY encountered problems on #{nerror} items")
end

def departmentEqualsCertificate()
  setLogger("#{ENV['DSPACE_HOME']}/log/departmentEqualsCertificate.log")

# colmap - maps shortened collection's name to collection pointers
  colmap = {}; DSpace.fromString($root).collections.each {|c| colmap[shortCollectionName(c)] = c}

# go over all archived items with the given year_metadata_value equal to $year
# and compare department value with certificate value
  nitems, narchived, nerror = 0, 0, 0;
  items = getClassYearItems
  items.each do |i|
    begin
      nitems += 1
      if i.archived? then
        # add i to all collections indicated in its pu.department value IF collection is not already in that collection
        narchived += 1
        dept_vals = i.getMetadata("pu", "department", nil, "*")
        if (dept_vals.length > 1) then
          $logger.warn "#{i.to_s}  has multiple department values"
        end
        cert_vals = i.getMetadata("pu", "certificate", nil, "*")
        $logger.info "#{dept_vals.inspect}\t\t#{cert_vals.inspect}"
        for dep in dept_vals do
          for c in cert_vals do
            if (c.value == dep.value) then
              $logger.error "#{i.getHandle}  in #{i.getOwningCollection().getName()} #{dep} == #{c}"
              nerror += 1
            else
              $logger.info "#{i.getHandle}  in #{i.getOwningCollection().getName()} #{dep} NOT #{c}"
            end
          end
        end
      end
    rescue Exception => e
      $logger.error "exception when processing item #{i.to_s}"
      $logger.error e.inspect
      nerror += 1
    end
  end
  $logger.info("SUMMARY processed #{narchived} items out of #{nitems} items")
  $logger.info("SUMMARY encountered problems on #{nerror} items")
end

# Uncomment functions as necessary
#compareDepartmentMetadataWithOwningCollection(true)
#DSpace.commit
#compareDepartmentMetadataWithOwningCollection(false)
#fixNullAbstract()
departmentEqualsCertificate
