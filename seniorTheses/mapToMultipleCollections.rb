#!/usr/bin/env jruby

# TODO: Find and remove duplication / repetition here and seniorTheses/cleanupAfterImport.rb

require 'lumberjack'
require 'cli/dconstants'

account = DConstants::LOGIN

log_file = "#{ENV['DSPACE_HOME']}/log/map2Collections.log"
logger = Lumberjack::Logger.new("#{log_file}", :buffer_size => 0) # Open a new log file with INFO level
logger.level = :info
puts "DEBUG logging action to  #{log_file}"

root = DConstants::SENIOR_THESIS_HANDLE
year = DConstants::DEFAULT_YEAR
year_metadata_field = "pu.date.classyear"

logger.info "START select #{year_metadata_field}=#{year} in #{root}"
logger.info "START login as  #{account}"

require 'dspace'
require 'cli/ditem'

DSpace.load
DSpace.login(account)
java_import org.dspace.core.Constants

def shortColectionName(c)
  c.getName.split(',')[0]
end

def doit()
collections = DSpace.fromString(root).collections

# colmap - maps shortened collection's name to collection pointers
colmap = {}; collections.each {|c| colmap[shortColectionName(c)] = c}

puts  colmap.keys.inspect

# go over all archived items with the given year_metadata_field equal to year
items = DSpace.findByMetadataValue(year_metadata_field, year, nil)
nitems, narchived, nmapped, nerror = 0, 0, 0, 0;
items.each do |i|
  begin
    nitems += 1
    if i.archived? then
      # add i to all collections indicated in its pu.department value IF collection is not already in that collection
      narchived += 1
      owners = i.getCollections
      logger.debug "#{i.to_s}  in #{owners.collect {|o| o.getName}.inspect}"
      i.getMetadata("pu", "department", nil, "*").each do |val|
        map_to_col = colmap[val.value]
        if (map_to_col) then
          if owners.include? map_to_col then
            logger.info("ITEM #{i.getHandle}: already in '#{map_to_col.getName}'")
          else
            logger.info("ITEM #{i.getHandle}: mapping to '#{map_to_col.getName}'")
            map_to_col.addItem(i)
            DSpace.create(i).index(true)
            nmapped += 1
          end
        else
          logger.error("ITEM #{i.getHandle}: could not find collection with name '#{val.value}'")
          nerror += 1
        end
      end
    end
  rescue Exception => e
    logger.error "exception when processing item #{i.to_s}"
    logger.error e.inspect
    nerror += 1
  end
end
logger.info("SUMMARY processed #{narchived} items out of #{nitems} items")
logger.info("SUMMARY added #{nmapped} collection mappings")
logger.info("SUMMARY encountered problems on #{nerror} items")
end

#DSpace.commit