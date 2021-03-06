#!/usr/bin/env jruby

# Set metadata value to "walk in access" prompt for all items in given year and
#   group_name. Iterate through, check policy, and change metadata if appropriate.

require 'highline/import'
require 'lumberjack'
require 'cli/dconstants'

account = DConstants::LOGIN

log_file = "#{ENV['DSPACE_HOME']}/log/muddWalking.log"

year = DConstants::DEFAULT_YEAR
year_metadata_field = 'pu.date.classyear'

# one of these needs to be manually commented-out
group_name = 'SrTheses_Bitstream_Read_Princeton'
group_name = 'SrTheses_Bitstream_Read_Mudd'

set_field = %w[dc rights accessRights]
set_value = 'Walk-in Access. This thesis can only be viewed on computer terminals at the ' +
            '<a href="http://mudd.princeton.edu">Mudd Manuscript Library</a>. '

puts 'set metadata value '
puts "     #{set_field} to '#{set_value}'"
puts "on all items with #{year_metadata_field}=#{year},"
puts "  that have an ORIGINAL bitstream with a READ policy #{group_name}"

puts "\nlogin as  #{account}"

puts "\nlogging action to  #{log_file}"

require 'dspace'
DSpace.load
DSpace.login(account)
java_import org.dspace.core.Constants

logger = Lumberjack::Logger.new(log_file.to_s, buffer_size: 0)  # Open a new log file with INFO level
logger.level = :debug

group = DGroup.find(group_name)
raise "unknown GROUP #{group_name}" unless group

items = DSpace.findByMetadataValue(year_metadata_field, year, nil)
items.each do |i|
  logger.debug i.to_s
  i.getBundles.each do |bdl|
    next unless 'ORIGINAL' == bdl.getName

    bdl.getBitstreamPolicies.each do |pol|
      next unless pol.getGroup && (pol.getAction == Constants::READ)

      logger.debug "#{i} #{bdl.getName} READ #{pol.getGroup.getName}"
      doit = pol.getGroup == group and Constants::READ == pol.getAction
      next unless doit

      i.setMetadataSingleValue(set_field[0], set_field[1], set_field[2], nil, set_value)
      logger.info "ITEM.#{i.getID} #{i.getHandle} setting #{set_field.inspect}"
      i.update
    end
  end
end

DSpace.commit
