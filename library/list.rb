#!/usr/bin/env jruby
require 'dspace'

# Neatly list all items in a community

DSpace.load

# postgres
# fromString = "COMMUNITY.145"

# QUESTION: This hard-coded handle is not found elsewhere. Any thoughts of where
#   it's from?
com = DSpace.fromString('88435/dsp01g732d9019')

def tsv_title
  puts %i[acaesioned depositor collection title url].collect { |key|  key.to_s }.join("\t")
end

def tsv_out(h)
  puts %i[acaesioned depositor collection title url].collect { |key|  h[key]}.join("\t")
end

def listAllItems(com)
  puts tsv_title
  colls = com.getAllCollections
  colls.each do |col|
    iter = col.items
    while iter.hasNext
      i = iter.next
      h = {}
      h[:title] = i.getMetadataByMetadataString('dc.title').collect { |v| v.value }
      h[:collection] = col.getName
      h[:depositor] = i.getMetadataByMetadataString('pu.depositor').collect { |v| v.value }
      # QUESTION: What is "acaesioned"
      h[:acaesioned] = i.getMetadataByMetadataString('dc.date.accessioned').collect { |v| v.value }
      h[:url] = i.getMetadataByMetadataString('dc.identifier.uri').collect { |v| v.value }
      tsv_out(h)
    end
  end
  colls
end

listAllItems(com)
