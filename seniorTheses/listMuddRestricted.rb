#!/usr/bin/env jruby

# list items in the groups listed below and place their policies into a table to std out.
# TODO: Double check overlap between this and seniorTheses/listEmbargoed.rb

require 'dspace'
require 'cli/dconstants'

DSpace.load

after_year = DConstants::DEFAULT_YEAR

puts ['Handle', 'Year', 'Mudd', 'READ_group', 'Bitstream Name'].join "\t"

%w[SrTheses_Bitstream_Read_Mudd SrTheses_Item_Read_Anonymous].each do |group_name|
  mudds = DSpace.findByGroupPolicy(group_name, DConstants::READ, DConstants::BITSTREAM)
  mudds.each do |b|
    i = b.getParentObject
    year = i.getMetadataByMetadataString('pu.date.classyear')[0].value.to_i
    walkin = i.getMetadataByMetadataString('pu.mudd.walkin')
    puts [i.getHandle, year, walkin, group_name, b.getName].join "\t" if year > after_year
  end
end
