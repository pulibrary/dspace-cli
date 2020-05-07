require 'dspace'
DSpace.load

# Class modeling a Bitstream
# @see https://github.com/DSpace/DSpace/blob/dspace-5.3/dspace-api/src/main/java/org/dspace/content/Bitstream.java
class DBitstream

  # Retrieve all Bitstreams without metadata related to these in the database
  # @return [Array<org.dspace.content.Object>]
  def self.allWithoutMetadata()
    java_import org.dspace.storage.rdbms.DatabaseManager
    sql = 'SELECT  DISTINCT(BITSTREAM_ID)  from BITSTREAM ' +
          ' LEFT JOIN METADATAVALUE ' +
          ' ON BITSTREAM.BITSTREAM_ID = METADATAVALUE.RESOURCE_ID ' +
          ' WHERE METADATAVALUE.TEXT_VALUE  IS NULL AND METADATAVALUE.METADATA_FIELD_ID IS NULL'
      tri = DatabaseManager.queryTable(DSpace.context, "Bitstream", sql)
      dsos = [];
      while (iter = tri.next())
        dsos << self.find(iter.getIntColumn("bitstream_id"))
      end
      tri.close
      return dsos
  end
end

def print_bitstream(d)
  item = d.getParentObject()
  return if item.nil?
  handle = item.nil? ? 'no-handle' : item.getHandle
  puts ([d.getID, handle, year] + DSpace.create(d).parents()).join("\t")
end

def doit()
  dsos = DBitstream.allWithoutMetadata
  dsos.each do |d|
    print_bitstream(d)
  end
  dsos.length
end

doit()
