#!/usr/bin/env jruby  

# 

require 'xmlsimple'
require 'dspace'

require 'cli/dconstants'

#DSpace.load

#postgres
# fromString = "COMMUNITY.145"

# dataspace
fromString = DConstants::SENIOR_THESIS_HANDLE

com = DSpace.fromString(fromString)

# Create a CSV of all embargoed items
def embargoed_csv(com)
  handle, col, klass, nAuthor, embargo = ['handle', 'collection', 'year', '#author', 'embargo']
  items = DSpace.findByMetadataValue('pu.embargo.terms', nil, nil)
  ihash = []
  items.each do |i|
    next unless i.getHandle
    next unless DSpace.create(i).parents.index(com)
    nAuth = i.getMetadataByMetadataString("dc.contributor.author").length
    h = {handle => i.getHandle}
    h[col] = i.getParentObject.getName
    h[klass] = i.getMetadataByMetadataString("pu.date.classyear").collect {|v| v.value}
    h[nAuthor] = nAuth
    h[embargo] = i.getMetadataByMetadataString("pu.embargo.terms").collect {|v| v.value}
    ihash << h
  end

  csv_out(ihash, ['embargo', 'year', '#author', 'handle', 'collection'])
end

# create a hash of all items in a group after given year
def group_restricted(group_name, after_year)
  java_import java.util.Calendar
  ihash = []
  fields = ['handle', 'collection', 'year', 'goup', 'embargo', 'group', 'accessRights']
  handle, col, klass, embargo, group, rights = fields
  cur_year = Calendar.getInstance().get(Calendar::YEAR)
  while (cur_year > after_year)
    items = DSpace.findByMetadataValue('pu.date.classyear', cur_year, nil)

    cur_year = cur_year -1
  end
  mudds = DSpace.findByGroupPolicy(group_name, DConstants::READ, DConstants::BITSTREAM)
  mudds.each do |b|
    i = b.getParentObject
    puts i
    h = {handle => i.getHandle}
    h[klass] = i.getMetadataByMetadataString("pu.date.classyear").collect {|v| v.value}[0]
    if (h[klass].to_i > after_year) then
      h[col] = i.getParentObject.getName
      h[group] = group_name
      h[embargo] = i.getMetadataByMetadataString("pu.embargo.terms").collect {|v| v.value}
      h[rights] = i.getMetadataByMetadataString("dc.rights.accessRights").collect {|v| v.value.gsub(/\..*/, '')}
      ihash << h
    end
  end

  csv_out(ihash, fields)
end

# TODO: This should be centralized. It is repeated throughout many scripts and directories.
def csv_out(ihash, fields)
  puts fields.join("\t")
  ihash.each do |h|
    puts fields.collect {|f| h[f]}.join("\t").gsub(/\n/, ' ').gsub(/\r/, ' ')
  end
end

#embargoed_csv(com)

["SrTheses_Bitstream_Read_Mudd", "SrTheses_Bitstream_Read_Princeton", "SrTheses_Item_Read_Anonymous"].each do |group_name|
  group_restricted(group_name, 2016)
end
