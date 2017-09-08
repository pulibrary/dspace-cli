#!/usr/bin/env jruby
require 'lumberjack'

account = "monikam"

log_file ="#{ENV['DSPACE_HOME']}/log/map2Collections.log"
logger = Lumberjack::Logger.new("#{log_file}", :buffer_size => 0) # Open a new log file with INFO level
logger.level = :debug
puts "DEBUG logging action to  #{log_file}"

root ="88435/dsp019c67wm88m"

logger.info "START login as  #{account}"

require 'dspace'
require 'cli/ditem'

DSpace.load
DSpace.login(account)
java_import org.dspace.core.Constants

def shortColectionName(c)
  c.getName.split(',')[0]
end

collections = DSpace.fromString(root).collections
colmap = {}; collections.each {|c| colmap[shortColectionName(c)] = c}
logger.debug colmap.keys.inspect

certificates = ['Global Health and Health Policy Program']

for cert in certificates do
  nitems, narchived, nmapped, nerror = 0, 0, 0, 0;
  logger.debug("CERTIFICATE " + cert)

  items = DSpace.findByMetadataValue('pu.certificate', cert, DConstants::ITEM)
  items.each do |i|
    begin
      nitems += 1
      if i.archived? then
        narchived += 1
        owners = i.getCollections
        i.getMetadata("pu", "certificate", nil, "*").each do |val|
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