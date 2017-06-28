#!/usr/bin/env jruby
require 'dspace'
DSpace.load

puts ["Handle", "Year", "READ_restriction",  "Bitstream Name",].join "\t"

["SrTheses_Bitstream_Read_Mudd", "SrTheses_Bitstream_Read_Princeton", "SrTheses_Item_Read_Anonymous"].each do |group_name|
  mudds = DSpace.findByGroupPolicy(group_name, DConstants::READ, DConstants::BITSTREAM)
  mudds.each do |b|
    i = b.getParentObject
    year = i.getMetadataByMetadataString("pu.date.classyear").collect { |v| v.value }.join(",")
    puts [i.getHandle, year, group_name, b.getName].join "\t"
  end

end

