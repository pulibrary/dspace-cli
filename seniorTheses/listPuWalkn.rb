#!/usr/bin/env jruby

# List items with the "walkin" policy

require 'xmlsimple'
require 'dspace'
require 'cli/dconstants'

DSpace.load

# postgres
# fromString = "COMMUNITY.145"

# dataspace
fromString = DConstants::SENIOR_THESIS_HANDLE

com = DSpace.fromString(fromString)

def pu_walkin
  handle = 'handle'
  col = 'collection'
  klass = 'year'
  nAuthor = '#author'
  embargo = 'embargo'
  items = DSpace.findByMetadataValue('pu.mudd.walkin', nil, nil)
  ihash = []
  items.each do |i|
    next unless i.getHandle

    nAuth = i.getMetadataByMetadataString('dc.contributor.author').length
    next unless nAuth > 1

    h = { handle => i.getHandle }
    h[col] = i.getParentObject.getName
    h[klass] = year
    h[nAuthor] = nAuth
    h[embargo] = i.getMetadataByMetadataString('pu.embargo.terms').collect { |v| v.value }
    ihash << h
  end

  csv_out(ihash, ['embargo', 'year', '#author', 'handle', 'collection'])
end

# TODO: Centralize this function
def csv_out(ihash, fields)
  puts fields.join("\t")
  ihash.each do |h|
    puts fields.collect { |f| h[f] }.join("\t").gsub(/\n/, ' ').gsub(/\r/, ' ')
  end
end

pu_walkin
