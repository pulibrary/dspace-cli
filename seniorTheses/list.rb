#!/usr/bin/env jruby  
require 'xmlsimple'
require 'dspace'

DSpace.load

# dataspace
fromString = '88435/dsp019c67wm88m'

com = DSpace.fromString(fromString)

def all_xml
  com.getCollections.each do |col|
    one_xml(col)
  end
end

def one_xml(col)
  puts "#{col.toString} #{col.getName}"
  File.open(col.toString + ".xml", 'w') do |out|
    items = col.items
    ihash = []
    while (i = items.next)
      h = {}
      h[:title] = i.getMetadataByMetadataString("dc.title").collect {|v| v.value}
      h[:author] = i.getMetadataByMetadataString("dc.contributor.author").collect {|v| v.value}
      h[:advisor] = i.getMetadataByMetadataString("dc.contributor.advisor").collect {|v| v.value}
      h[:classyear] = i.getMetadataByMetadataString("pu.date.classyear").collect {|v| v.value}
      h[:department] = i.getMetadataByMetadataString("pu.department").collect {|v| v.value}
      h[:url] = i.getMetadataByMetadataString("dc.identifier.uri").collect {|v| v.value}
      ihash << h
    end
    colurl = "http://arks.princeton.edu/ark:/#{col.getHandle()}"
    out.puts XmlSimple.xml_out({:name => col.getName, :url => colurl, :item => ihash}, :root_name => 'collection')
  end

end

def all_year_hsh(year)
  items = DSpace.findByMetadataValue('pu.date.classyear', year, nil)
  cols = {};
  items.each do |i|
    if (i.getHandle) then
      h = {}
      h[:title] = i.getMetadataByMetadataString("dc.title").collect {|v| v.value}
      h[:author] = i.getMetadataByMetadataString("dc.contributor.author").collect {|v| v.value}
      h[:advisor] = i.getMetadataByMetadataString("dc.contributor.advisor").collect {|v| v.value}
      h[:classyear] = i.getMetadataByMetadataString("pu.date.classyear").collect {|v| v.value}
      h[:department] = i.getMetadataByMetadataString("pu.department").collect {|v| v.value}
      h[:authorid] = i.getMetadataByMetadataString("pu.contributor.authorid").collect {|v| v.value}
      h[:advisorid] = i.getMetadataByMetadataString("pu.contributor.advisorid").collect {|v| v.value}
      h[:certificate] = i.getMetadataByMetadataString("pu.certificate").collect {|v| v.value}
      h[:embaro_lift] = i.getMetadataByMetadataString("pu.embargo.lift").collect {|v| v.value}
      h[:embargo_term] = i.getMetadataByMetadataString("pu.embargo.lift").collect {|v| v.value}
      h[:access_right] = i.getMetadataByMetadataString("dc.rights.accessRights").collect {|v|
        if v.value then
          v.value.gsub(/\..*/, '')
        else
          ""
        end}
      h[:url] = i.getMetadataByMetadataString("dc.identifier.uri").collect {|v| v.value}
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

def bit_groups(i)
  DSpace.create(i).bitstreams().collect {|b| DSpace.create(b).policies()}.flatten.collect {|p| p[:group]}.uniq
end

def year_hash(year, fields = nil)
  fields ||= ['handle', 'klass', "dc.contributor.author", "dc.contributor.advisor", 'dc.date.created', 'pu.department', 'pu.certificate', "dc.contributor",
              'pu.embargo.terms', 'dc.title']
  items = DSpace.findByMetadataValue('pu.date.classyear', year, nil)
  ihash = []
  items.each do |i|
    next unless i.getHandle
    h = {'ID' => i.getID()}
    fields.each do |f|
      if (f == 'handle') then
        h[f] = i.getHandle()
      elsif (f == 'klass') then
        h[f] = year
      elsif (f == 'bit_groups') then
        h[f] = bit_groups(i)
      elsif (f != 'ID') then
        vals = i.getMetadataByMetadataString(f).collect {|v| v.value}
        vals = vals.collect {|v| v.gsub(/\..*/, '')} if (f == 'pu.mudd.walkin')
        h[f] = vals
      end
    end
    ihash << h
  end
  return ihash
end

def year_handles(year)
  items = DSpace.findByMetadataValue('pu.date.classyear', year, nil)
  h = items.collect {|i| i.getHandle}
  puts h.join("\n")
end

def csv_out(ihash, fields)
  puts fields.join("\t")
  ihash.each do |h|
    puts fields.collect {|f| h[f].to_s}.join("\t").gsub(/\n/, ' ').gsub(/\r/, ' ')
  end
end

def prefixed_csv_out(ihash, fields)
  ihash.each do |h|
    prefixed = fields.collect {|f| "#{f}=#{h[f]}"}
    puts prefixed.join("\t").gsub(/\n/, ' ').gsub(/\r/, ' ')
  end
end


# -- call one of these to generate report

def year_csv(year)

  fields = ['ID', 'handle', 'klass', "dc.contributor.author", 'pu.department', 'dc.date.accessioned',
            'bit_groups', 'pu.embargo.lift', 'pu.embargo.terms', 'pu.mudd.walkin', 'dc.rights.accessRights']

  fields = ['ID', 'handle', 'klass', 'dc.date.issued', 'dc.date.created', 'dc.date.accessioned', "dc.contributor.author"]
  for year in [2016] do
    csv_out(year_hash(year, fields), fields)
  end
end

def all_xml_year(year)
  col_hsh_print(all_year_hsh(year))
end

def col_xml(handle)
  col = DSpace.fromString(handle)
  one_xml(col)
end


col_xml('88435/dsp01fx719m510')
