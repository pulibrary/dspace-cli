#!/usr/bin/env jruby

# Get a report of all items in a class year.

require 'highline'
require 'dspace'

def report(year)
  puts ['Collection', 'Year', 'Status', '#Bistreams', 'Formats', 'Item', 'Authors', 'Advisors', 'Title'].join("\t")

  dsos = DSpace.findByMetadataValue('pu.date.classyear', year, DConstants::ITEM)
  dsos.each do |d|
    print_item(d)
  end
end

def print_item(item)
  authors = item.getMetadataByMetadataString('dc.contributor.author').collect { |v| v.value }.join ','

  advisors_plus =  item.getMetadataByMetadataString('dc.contributor.advisor').collect { |v| v.value }
  advisors_plus += item.getMetadataByMetadataString('dc.contributor').collect { |v| v.value }
  advisors_plus = advisors_plus.join ','

  title = item.getName
  year = item.getMetadataByMetadataString('pu.date.classyear').collect { |v| v.value }.join ','

  archived = item.isArchived ? 'archived' :  'not-archived'
  parent_name = item.getParentObject.nil? ? '' : item.getParentObject.getName
  item_ref = item.getHandle.nil? ? "ITEM.#{item.getID}" : item.getHandle

  bits = DSpace.create(item).bitstreams
  formats = bits.collect { |b| b.getFormat.getMIMEType }.uniq.join(',')

  vals = [parent_name, year, archived, bits.length, formats, item_ref, authors, advisors_plus, title]
  puts vals.join("\t").gsub("\n", ' ').gsub("\r", ' ')
end

if ARGV.length != 1
  puts 'provide classyear parameter'
  exit(1)
end
DSpace.load
report(ARGV[0])
