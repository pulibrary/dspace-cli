#!/usr/bin/env jruby

# UNFINISHED
# 
# This script would fail on running. The year_hash function is called at the end
# but is not defined. Presumably this is a copy and paste error, but since it's
# a slip-up that suggests it hasn't been run for a while, perhaps it deserves
# closer review.

require 'dspace'
DSpace.load


def year_csv(year)
  item_id, handle, col, klass, nbisttreams =
      ['item_id', 'handle', 'collection',  'year', 'nbitstreams']

  items = DSpace.findByMetadataValue('pu.date.classyear', year, nil)
  handles = items.select{ |i| i.getHandle }.collect{ |i| i.getHandle }
  ihash = []
  handles.each do |h|
    i = DSpace.fromString h
    h = {}
    h[klass] = year
    h[item_id] = i.getID
    h[handle] = i.getHandle
    h[col] = i.getParentObject.getName
    h[nbisttreams] = DSpace.create(i).bitstreams.length
    ihash << h
  end

  csv_out(ihash, [nbisttreams, klass, handle, col])
end

def csv_out(ihash, fields)
  puts fields.join("\t")
  ihash.each do |h|
    puts fields.collect {|f| h[f]}.join("\t").gsub(/\n/, ' ').gsub(/\r/, ' ')
  end
end


year_hash(2015)
