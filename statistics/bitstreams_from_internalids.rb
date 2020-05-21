#!/usr/bin/env jruby

# Given a bitstream's internal ID from command line, print the matching bitstream's info

require 'dspace'

DSpace.load
java_import org.dspace.storage.rdbms.TableRow
java_import org.dspace.storage.rdbms.DatabaseManager
java_import org.dspace.core.Constants

# QUESTION: What is the difference between Internal IDs and a normal ID?
def find_bitstream(id)
  # get all bitstreams where id matches given parameter
  sql = "SELECT * FROM BITSTREAM WHERE INTERNAL_ID = '#{id}'";
  tri = DatabaseManager.queryTable(DSpace.context, "Bitstream",   sql)
  dsos = [];
  while (i = tri.next())
    dso =  DSpace.find('BITSTREAM', i.getIntColumn("bitstream_id"))
    dsos << dso
  end
  tri.close
  raise "more than one Bitstream match for #{id}" if dsos.length > 1
  return dsos[0]
end


while (line = ARGF.gets)
  internal_id = line.strip
  bit = find_bitstream(internal_id);
  vals = [internal_id]
  if (bit) then
    vals +=  [bit.dso.getID]
    bit.parents.each{ |p| vals += ["#{Constants.typeText[p.getType]}.#{p.getID}", p.getHandle()]}
  else
    vals += ['unknown']
  end
  puts vals.join("\t")
end

