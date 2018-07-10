#!/usr/bin/env jruby
require 'dspace'
DSpace.load


after_year = 2016

puts ["Handle", "Year", "Mudd", "READ_group",  "Bitstream Name",].join "\t"

["SrTheses_Bitstream_Read_Mudd", "SrTheses_Item_Read_Anonymous"].each do |group_name|
  mudds = DSpace.findByGroupPolicy(group_name, DConstants::READ, DConstants::BITSTREAM)
  mudds.each do |b|
    i = b.getParentObject
    year = i.getMetadataByMetadataString("pu.date.classyear")[0].value.to_i
    walkin = i.getMetadataByMetadataString("pu.mudd.walkin")
    if (year > after_year) then
      puts [i.getHandle, year, walkin, group_name, b.getName].join "\t"
    end
  end

end

