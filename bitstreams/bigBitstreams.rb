require 'dspace'
DSpace.load

class DBitstream

  def self.listBiggerThan(num)
    java_import org.dspace.storage.rdbms.DatabaseManager
    sql = 'SELECT  BITSTREAM_ID, SIZE_BYTES from BITSTREAM '
      tri = DatabaseManager.queryTable(DSpace.context, "Bitstream", sql)
      dsos = [];
      while (iter = tri.next())
        s = iter.getLongColumn("SIZE_BYTES");
        if (s >= num) then
          dsos << self.find(iter.getIntColumn("bitstream_id"))
          print_bitstream self.find(iter.getIntColumn("bitstream_id"))
        end
      end
      tri.close
      return dsos
  end
end

def print_headers
  puts ["SizeBytes", "Bitstream_ID", "handle", "BitstreamName"].join "\t"
end
def print_bitstream(d)
  item = d.getParentObject()
  handle = item.nil? ? 'no-handle' : item.getHandle
  puts [d.getSize, d.getID, handle, d.getName].join("\t")
end

def doit(bigger)
  print_headers
  DBitstream.listBiggerThan(bigger)
end

doit(1024 * 1024 *1024)