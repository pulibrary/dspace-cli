require 'dspace'
DSpace.load

# Class modeling a Bitstream for a given Item
# @see https://github.com/DSpace/DSpace/blob/dspace-5.3/dspace-api/src/main/java/org/dspace/content/Bitstream.java
class DBitstream

  # Retrieve all DSpace Items larger than a certain number of bytes
  # @param num [Integer]
  # @return [Array<org.dspace.content.Object>]
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
