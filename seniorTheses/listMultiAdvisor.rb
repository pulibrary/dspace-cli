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
  handle, col, klass, nAdvisor, nAdvisor2, embargo = ['handle', 'collection', 'year', '#advisor', '#advisor2', 'embargo']
  items = DSpace.findByMetadataValue('pu.date.classyear', year, nil)
  ihash= []
  items.each do |i|
    next unless i.getHandle
    nAdv = i.getMetadataByMetadataString("dc.contributor.advisor").length
    nAdv2 = i.getMetadataByMetadataString("dc.contributor").length
    if (nAdv + nAdv2 > 1)
      h = {handle => i.getHandle}
      h[col] = i.getParentObject.getName
      h[klass] = year
      h[nAdvisor] = nAdv
      h[nAdvisor2] = nAdv2
      h[embargo] = i.getMetadataByMetadataString("pu.embargo.terms").collect { |v| v.value }
      ihash << h
    end
  end

  csv_out(ihash, [nAdvisor, nAdvisor2, embargo, klass, handle, col])
end

def csv_out(ihash, fields)
  puts fields.join("\t")
  ihash.each do |h|
    puts fields.collect { |f| h[f] }.join("\t").gsub(/\n/, ' ').gsub(/\r/, ' ')
  end
end

#year_csv(2017)
year_hash(2016)
year_hash(2015)


