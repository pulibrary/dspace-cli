#!/usr/bin/env jruby  
require 'xmlsimple'
require 'dspace'

require 'cli/dconstants'

DSpace.load

# dataspace
fromString = DConstants::SENIOR_THESIS_HANDLE
com = DSpace.fromString(fromString)

def all_year_hsh(year)
  items = DSpace.findByMetadataValue('pu.date.classyear', year, nil)
  cols = {};
  items.each do |i|
    if (i.getHandle) then
      h = {}
      h[:title] = i.getMetadataByMetadataString("dc.title").collect { |v| v.value }
      h[:author] = i.getMetadataByMetadataString("dc.contributor.author").collect { |v| v.value }
      h[:authorid] = i.getMetadataByMetadataString("pu.contributor.authorid").collect { |v| v.value }
      h[:advisor] = i.getMetadataByMetadataString("dc.contributor.advisor").collect { |v| v.value }
      h[:classyear] = i.getMetadataByMetadataString("pu.date.classyear").collect { |v| v.value }
      h[:department] = i.getMetadataByMetadataString("pu.department").collect { |v| v.value }
      h[:url] = i.getMetadataByMetadataString("dc.identifier.uri").collect { |v| v.value }
      cols[i.getParentObject] = [] unless cols[i.getParentObject]
      cols[i.getParentObject] << h
    end
  end
  return cols
end

def col_hsh_print(hsh)
  hsh.keys.each do |col|
    ihash = hsh[col]
    colurl = "http://arks.princeton.edu/ark:/#{col.getHandle()}"
    File.open(col.toString + ".xml", 'w') do |out|
      out.puts XmlSimple.xml_out({:name => col, :url => colurl, :item => ihash}, :root_name => 'collection')
    end
  end
end

def all_xml_year(year)
  col_hsh_print(all_year_hsh(year))
end

all_xml_year(2018) 
