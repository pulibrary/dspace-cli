#!/usr/bin/env jruby -I ../dspace-jruby/lib 
require 'xmlsimple'
require 'dspace'

DSpace.load
java_import org.dspace.authorize.AuthorizeManager


#postgres
# fromString = "COMMUNITY.145"

# dataspace
fromString = '88435/dsp019c67wm88m'

com = DSpace.fromString(fromString)

def year_csv(year)
  size, handle, col, fname, klass, has_embargo, policies = ['filesize MB', 'handle', 'collection', 'filename', 'year', 'embargo?', "policies"]

  items = DSpace.findByMetadataValue('pu.date.classyear', year, nil)
  handles = items.select{ |i| i.getHandle }.collect{ |i| i.getHandle }
  ihash= []
  n = 0;
  handles.each do |h|
    i = DSpace.fromString h
    DSpace.create(i).bitstreams.each do |b|
      h =  report_on(b)
      h[klass] = year
      h[handle] = i.getHandle
      h[col] = i.getParentObject.getName
      h[has_embargo] = (nil == i.getMetadata('pu.embargo.lift')) ? '----' : i.getMetadata('pu.embargo.lift')
      ihash << h
      break
    end
    n = n + 1
    if (n == 200) then
      DSpace.reload
      n = 0
    end

  end

  csv_out(ihash, [size, klass, handle, col, fname, has_embargo, policies])
end

def report_on(b)
  size, handle, col, fname, klass, has_embargo, policies = ['filesize MB', 'handle', 'collection', 'filename', 'year', 'embargo?', "policies"]
  h = {}
  h[fname] = b.getName
  h[size] = (1.0 * b.getSize) / (1024 * 1024)
  h[policies] = get_policies(b)
  return h
end

def get_policies(b)
  java_import org.dspace.storage.rdbms.DatabaseManager
  sql = "SELECT ACTION_ID,EPERSONGROUP_ID,EPERSON_ID FROM RESOURCEPOLICY WHERE  RESOURCE_ID = #{b.getID} AND RESOURCE_TYPE_ID = 0";
  tri = DatabaseManager.queryTable(DSpace.context, "RESOURCEPOLICY", sql)
  pols = []
  while (iter = tri.next()) do
    action = iter.getIntColumn("ACTION_ID")
    person = DEPerson.find iter.getIntColumn("EPERSON_ID")
    group = DGroup.find iter.getIntColumn("EPERSONGROUP_ID")
    group = group.getName if group
    pols << [action, person, group]
  end
  tri.close()
  return pols
end

def csv_out(ihash, fields)
  puts fields.join("\t")
  ihash.each do |h|
    puts fields.collect {|f| h[f]}.join("\t").gsub(/\n/, ' ').gsub(/\r/, ' ')
  end
end


if true then
  year_csv(2013)
  year_csv(2014)
  year_csv(2015)
  year_csv(2016)
#year_csv(2015)
end


