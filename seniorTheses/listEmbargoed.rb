#!/usr/bin/env jruby  
require 'xmlsimple'
require 'dspace'

DSpace.load

#postgres
# fromString = "COMMUNITY.145"

# dataspace
fromString = '88435/dsp019c67wm88m'

com = DSpace.fromString(fromString)

def embargoed_csv(com)
  handle, col, klass, nAuthor, embargo = ['handle', 'collection', 'year', '#author', 'embargo']
  items = DSpace.findByMetadataValue('pu.embargo.terms', nil, nil)
  ihash= []
  items.each do |i|
    next unless i.getHandle
    next unless DSpace.create(i).parents.index(com)
    nAuth = i.getMetadataByMetadataString("dc.contributor.author").length
    h = {handle => i.getHandle}
    h[col] = i.getParentObject.getName
    h[klass] = i.getMetadataByMetadataString("pu.date.classyear").collect { |v| v.value }
    h[nAuthor] = nAuth
    h[embargo] = i.getMetadataByMetadataString("pu.embargo.terms").collect { |v| v.value }
    ihash << h
  end

  csv_out(ihash, ['embargo', 'year', '#author', 'handle', 'collection'])
end

def csv_out(ihash, fields)
  puts fields.join("\t")
  ihash.each do |h|
    puts fields.collect { |f| h[f] }.join("\t").gsub(/\n/, ' ').gsub(/\r/, ' ')
  end
end

embargoed_csv(com)



