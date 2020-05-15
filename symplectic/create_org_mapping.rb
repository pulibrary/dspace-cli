#!/usr/bin/env jruby
require "highline/import"
require 'dspace'
require 'cli/dconstants'

DSpace.load
DSpace.login DConstants::LOGIN
puts "\n"
java_import org.dspace.storage.rdbms.DatabaseManager

com_name =  'All Content'
com = DSpace.findByMetadataValue('dc.title', com_name, DConstants::COMMUNITY)[0]
puts "no such community #{com_name}" unless com

collNames = com.getCollections.collect { |c| c.getName }

def getExistingOrgMappings
    sql = "SELECT KEY_TEXT, COLLECTION_ID FROM SYMPLECTIC_COLL_MAP";
    tri = DatabaseManager.queryTable(DSpace.context, "SYMPLECTIC_COLL_MAP", sql)
    map = {};
    while (iter = tri.next())
      map[iter.getStringColumn("KEY_TEXT")]  = iter.getIntColumn("COLLECTION_ID")
    end
    tri.close
    return map
end

def insertMapping(name, id)
  row = DatabaseManager.row("SYMPLECTIC_COLL_MAP");
  row.setColumn("key_text", name);
  row.setColumn("collection_id", id);
  DatabaseManager.insert(DSpace.context, row);
end

map = getExistingOrgMappings
DCollection.all.each  do |col|
  if  col.getParentObject.nil? then
    puts "WARNING: thats a stramge collection  #{col.getID}"
    next
  end
  org_name = "/Organisation/" + col.getName
  map_id =  map[org_name]
  if map_id.nil? then
    map_id = col.getID
    insertMapping(org_name, map_id)
    action = "mapped"
  else
    action = "exists"
  end
  puts "#{action} '#{org_name}'\tto COLLECTION.#{map_id} '#{DCollection.find(map_id).getName}'"
end


doit = ask "commit ? (Y/N) "
if (doit == "Y") then
  DSpace.commit
end
