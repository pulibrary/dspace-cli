#!/usr/bin/env jruby  
require 'xmlsimple'
require 'dspace'

DSpace.load

#postgres
# fromString = "COMMUNITY.145"

# dataspace
fromString = '88435/dsp019c67wm88m'

com = DSpace.fromString(fromString)

def all_xml
  com.getCollections.each do |col|
    puts "#{col.toString} #{col.getName}"
    File.open(col.toString + ".xml", 'w') do |out|
      items = col.items
      ihash = []
      while (i = items.next)
        h = {}
        h[:title] = i.getMetadataByMetadataString("dc.title").collect { |v| v.value }
        h[:author] = i.getMetadataByMetadataString("dc.contributor.author").collect { |v| v.value }
        h[:advisor] = i.getMetadataByMetadataString("dc.contributor.advisor").collect { |v| v.value }
        h[:classyear] = i.getMetadataByMetadataString("pu.date.classyear").collect { |v| v.value }
        h[:department] = i.getMetadataByMetadataString("pu.department").collect { |v| v.value }
        h[:url] = i.getMetadataByMetadataString("dc.identifier.uri").collect { |v| v.value }
        ihash << h
      end
      colurl = "http://arks.princeton.edu/ark:/#{col.getHandle()}"
      out.puts XmlSimple.xml_out({:name => col.getName, :url => colurl, :item => ihash}, :root_name => 'collection')
    end
  end
end

def all_year_hsh(year)
  items = DSpace.findByMetadataValue('pu.date.classyear', year, nil)
  cols = {};
  items.each do |i|
    if (i.getHandle) then
      h = {}
      h[:title] = i.getMetadataByMetadataString("dc.title").collect { |v| v.value }
      h[:author] = i.getMetadataByMetadataString("dc.contributor.author").collect { |v| v.value }
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


def year_csv(year, fields = nil)
  fields ||= ["dc.contributor.author", "dc.contributor.advisor", 'dc.date.created', 'pu.department', "dc.contributor", 'pu.embargo.terms', 'dc.title', 'dc.description.abstract']
  items = DSpace.findByMetadataValue('pu.date.classyear', year, nil)
  ihash= []
  items.each do |i|
      next unless i.getHandle
      h = { 'internal-id' => i }
      fields.each do |f|
        h[f] = i.getMetadataByMetadataString(f).collect { |v| v.value }.join("||")
      end
      ihash << h
    end
    csv_out(ihash, ['internal-id'] + fields)
end

def year_handles(year)
  items = DSpace.findByMetadataValue('pu.date.classyear', year, nil)
  h = items.collect { |i| i.getHandle }
  puts h.join("\n")
end

def csv_out(ihash, fields)
  puts fields.join("\t")
  ihash.each do |h|
    puts fields.collect{ |f| h[f]}.join("\t").gsub(/\n/, ' ').gsub(/\r/, ' ')
  end
end

#year_handles(2016)
def year_items(year)
items = DSpace.findByMetadataValue('pu.date.classyear', year, nil)
end

