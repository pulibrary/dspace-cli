#!/usr/bin/env jruby
require "highline/import"
require 'lumberjack'

account = "monikam"

log_file = "#{ENV['DSPACE_HOME']}/log/muddWalking.log"

year = 2016
year_metadata_field = "pu.date.classyear"
group_name = "SrTheses_Bitstream_Read_Princeton"
group_name = "SrTheses_Bitstream_Read_Mudd"

set_field = %w(dc rights accessRights)
set_value = 'Walk-in Access. ' +
    'This thesis can only be viewed on computer terminals at the ' +
    '<a href="http://www.princeton.edu/~mudd">Mudd Manuscript Library</a>. ' +
    'For more information or to order a copy contact ' +
    '<a href="mailto:mudd@princeton.edu">mudd@princeton.edu</a>.'

puts 'set metadata value '
puts "     #{set_field} to '#{set_value}'"
puts "on all items with #{year_metadata_field}=#{year},"
puts "  that have an ORIGINAL bitstream with a READ policy #{group_name}"

puts "\nlogin as  #{account}"

puts "\nlogging action to  #{log_file}"

ask 'ctr-c to abort'

require 'dspace'
DSpace.load
DSpace.login(account)
java_import org.dspace.core.Constants

logger = Lumberjack::Logger.new("#{log_file}", :buffer_size => 0)  # Open a new log file with INFO level
logger.level = :debug

group = DGroup.find(group_name)
raise "unknown GROUP #{group_name}" unless group

items = DSpace.findByMetadataValue(year_metadata_field, year, nil)
items.each do |i|
  logger.debug "#{i.to_s}"
  i.getBundles.each do |bdl|
    if "ORIGINAL" == bdl.getName then
      bdl.getBitstreamPolicies.each do |pol|
        if (pol.getGroup and pol.getAction == Constants::READ) then
          logger.debug "#{i.to_s} #{bdl.getName} READ #{pol.getGroup.getName }"
          doit = pol.getGroup == group and Constants::READ == pol.getAction
          if (doit) then
            i.setMetadataSingleValue(set_field[0], set_field[1], set_field[2], nil, set_value)
            logger.info "ITEM.#{i.getID} #{i.getHandle} setting #{set_field.inspect}"
          end
        end
      end
    end
  end
end

ask 'commit or ctr-c to abort'
logger.info "commiting changes"
DSpace.commit
