#!/usr/bin/env jruby  
require 'xmlsimple'
require 'dspace'

DSpace.load

#postgres
# fromString = "COMMUNITY.145"

# dataspace
fromString = '88435/dsp019c67wm88m'

com = DSpace.fromString(fromString)

def year_csv(year)
  size, sizeBytes, handle, col, fname, klass = ['filesize MB', 'filesize B', 'handle', 'collection', 'filename', 'year']
  items = DSpace.findByMetadataValue('pu.date.classyear', year, nil)
  ihash= []
  items.each do |i|
    next unless i.getHandle
    DSpace.create(i).bitstreams.each do |b|
      h = {handle => i.getHandle}
      h[col] = i.getParentObject.getName
      h[klass] = year
      h[fname] = b.getName
      h[size] = (1.0 * b.getSize) / (1024 * 1024)
      h[sizeBytes] = b.getSize
      ihash << h
    end
  end

  csv_out(ihash, ['filesize MB', 'filesize B', 'year', 'handle', 'collection', 'filename'])
end

def csv_out(ihash, fields)
  puts fields.join("\t")
  ihash.each do |h|
    puts fields.collect{ |f| h[f]}.join("\t").gsub(/\n/, ' ').gsub(/\r/, ' ')
  end
end

year_csv(2016)
year_csv(2015)


