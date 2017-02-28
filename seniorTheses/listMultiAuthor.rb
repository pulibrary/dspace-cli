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

year_csv(2016)
year_csv(2015)


