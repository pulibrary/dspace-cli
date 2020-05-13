#!/usr/bin/env jruby  

# UNFINISHED
# 
# This script would fail on running. The year_hash function is called at the end
# but is not defined. Presumably this is a copy and paste error, but since it's
# a slip-up that suggests it hasn't been run for a while, perhaps it deserves
# closer review.

require 'xmlsimple'
require 'dspace'

DSpace.load

#postgres
# fromString = "COMMUNITY.145"

# dataspace
fromString = '88435/dsp019c67wm88m'

com = DSpace.fromString(fromString)

def year_csv(year)
  handle, col, klass, nAuthor, embargo = ['handle', 'collection', 'year', '#author', 'embargo']
  items = DSpace.findByMetadataValue('pu.date.classyear', year, nil)
  ihash= []
  items.each do |i|
    next unless i.getHandle
    nAuth = i.getMetadataByMetadataString("dc.contributor.author").length
    if (nAuth > 1)
      h = {handle => i.getHandle}
      h[col] = i.getParentObject.getName
      h[klass] = year
      h[nAuthor] = nAuth
      h[embargo] = i.getMetadataByMetadataString("pu.embargo.terms").collect { |v| v.value }
      ihash << h
    end
  end

  csv_out(ihash, ['embargo', 'year', '#author', 'handle', 'collection'])
end

def csv_out(ihash, fields)
  puts fields.join("\t")
  ihash.each do |h|
    puts fields.collect { |f| h[f] }.join("\t").gsub(/\n/, ' ').gsub(/\r/, ' ')
  end
end

year_hash(2016)
year_hash(2015)


