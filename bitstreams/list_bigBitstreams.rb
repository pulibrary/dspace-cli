require 'dspace'
DSpace.load

# TODO: add this to cli/dbistream.rb
class DBitstream

  # return list of unwrapped bitstream objects 
  # TODO: Separate out print functionality
  def self.listBiggerThan(num)
    java_import org.dspace.storage.rdbms.DatabaseManager

    # Get bitstream id and its size
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

# given a java bitstream object, print out the size, id, handle, and name
def print_bitstream(d)
  item = d.getParentObject()
  handle = item.nil? ? 'no-handle' : item.getHandle
  puts [d.getSize, d.getID, handle, d.getName].join("\t")
end

# implement functions above
def doit(bigger)
  print_headers
  DBitstream.listBiggerThan(bigger)
end

# TODO: set 1024**3 as default value of num in listBiggerThan and remove here
doit(1024 * 1024 *1024)