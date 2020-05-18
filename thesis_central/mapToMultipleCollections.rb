#!/usr/bin/env jruby
require 'lumberjack'
require 'cli/dconstants'

account = DConstants::LOGIN

log_file = "#{ENV['DSPACE_HOME']}/log/map2Collections.log"
$logger = Lumberjack::Logger.new("#{log_file}", :buffer_size => 0) # Open a new log file with INFO level
$logger.level = :debug
puts "DEBUG logging action to  #{log_file}"


$logger.info "START login as  #{account}"

require 'dspace'
require 'cli/ditem'

DSpace.load
DSpace.login(account)
java_import org.dspace.core.Constants

def shortColectionName(c)
  c.getName.split(',')[0]
end


def map_to_cert_collections(i, colmap)
  nmapped, nerror = 0, 0
  if i.archived? then
    owners = i.getCollections
    i.getMetadata("pu", "certificate", nil, "*").each do |val|
      map_to_col = colmap[val.value]
      if (map_to_col) then
        if owners.include? map_to_col then
          $logger.info("ITEM #{i.getHandle}: already in '#{map_to_col.getName}'")
        else
          $logger.info("ITEM #{i.getHandle}: mapping to '#{map_to_col.getName}'")
          map_to_col.addItem(i)
          DSpace.create(i).index(true)
          nmapped = 1
        end
      else
        $logger.error("ITEM #{i.getHandle}: could not find collection with name '#{val.value}'")
        nerror = 1
      end
    end
  end
  return nmapped, nerror
end

def make_colmap(root)
  collections = DSpace.fromString(root).collections
  colmap = {}; collections.each {|c| colmap[shortColectionName(c)] = c}
  return colmap
end

def map_all(year)

  root = "88435/dsp019c67wm88m"
  colmap = make_colmap(root)
  $logger.debug colmap.keys.inspect

  narchived, nmapped, nerror = 0, 0, 0;
  items = DSpace.findByMetadataValue('pu.date.classyear', year, DConstants::ITEM)
  items.each do |i|
    begin
      if (i.archived?) then
        mapped, err = map_to_cert_collections(i, colmap)
        narchived += 1
        nmapped += mapped
        nerror += err

        if (mapped != 0) then
          DSpace.commit
          # break here for testing - so only one mapping is performed
          #break
        end
      end

    rescue Exception => e
      $logger.error "exception when processing item #{i.to_s}"
      $logger.error e.inspect
      nerror += 1
    end
  end
  $logger.info("SUMMARY nitems with pu.date.classyear=#{year} : #{items.length}")
  $logger.info("SUMMARY narchived #{narchived} items ")
  $logger.info("SUMMARY added #{nmapped} collection mappings")
  $logger.info("SUMMARY encountered problems on #{nerror} items")

end

def test()
  root = DConstants::SENIOR_THESIS_HANDLE
  colmap = make_colmap(root)
  i = DSpace.fromString('88435/dsp01gb19f854b')

  i = DSpace.fromString('99999/fk4tf11p6j')
  map_to_cert_collections(i, colmap)

end


map_all(DConstants::DEFAULT_YEAR)
