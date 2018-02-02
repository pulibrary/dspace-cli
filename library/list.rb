#!/usr/bin/env jruby
require 'dspace'

DSpace.load

#postgres
# fromString = "COMMUNITY.145"

com = DSpace.fromString('88435/dsp01g732d9019')

def tsv_title
  puts [:acaesioned, :depositor, :collection, :title, :url].collect {|key|  key.to_s}.join("\t")
end
def tsv_out(h)
  puts [:acaesioned, :depositor, :collection, :title, :url].collect {|key|  h[key]}.join("\t")
end

def listAllItems(com)
  puts tsv_title
  colls = com.getCollections()
  com.getSubcommunities.each do |sub|
    colls = colls + sub.getCollections()
  end
  colls.each do |col|
    iter = col.items
    while (iter.hasNext)
      i = iter.next
      h = {}
      h[:title] = i.getMetadataByMetadataString("dc.title").collect { |v| v.value }
      h[:collection] = col.getName()
      h[:depositor] = i.getMetadataByMetadataString("pu.depositor").collect { |v| v.value }
      h[:acaesioned] = i.getMetadataByMetadataString("dc.date.accessioned").collect { |v| v.value }
      h[:url] = i.getMetadataByMetadataString("dc.identifier.uri").collect { |v| v.value }
      tsv_out(h)
    end
  end
  colls
end

listAllItems(com)