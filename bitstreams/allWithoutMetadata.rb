# Print out all bitstreams that don't have metadata

require 'dspace'

DSpace.load

# TODO: Add this class method to cli/dbitstream.rb
class DBitstream
  # get all bitstreams ids that don't have metadata
  def self.allWithoutMetadata
    java_import org.dspace.storage.rdbms.DatabaseManager

    # Get all unique bistream ids where there metadatavalues are null
    sql = 'SELECT  DISTINCT(BITSTREAM_ID)  from BITSTREAM ' +
          ' LEFT JOIN METADATAVALUE ' +
          ' ON BITSTREAM.BITSTREAM_ID = METADATAVALUE.RESOURCE_ID ' +
          ' WHERE METADATAVALUE.TEXT_VALUE  IS NULL AND METADATAVALUE.METADATA_FIELD_ID IS NULL'
    tri = DatabaseManager.queryTable(DSpace.context, 'Bitstream', sql)
    dsos = []
    while (iter = tri.next)
      dsos << find(iter.getIntColumn('bitstream_id'))
    end
    tri.close
    dsos
  end
end

# given bitstreams, print tabulated data
def print_bitstream(d)
  item = d.getParentObject
  return if item.nil?

  handle = item.nil? ? 'no-handle' : item.getHandle
  puts ([d.getID, handle, year] + DSpace.create(d).parents).join("\t")
end

# Print out all bitstreams that don't have metadata
def doit
  dsos = DBitstream.allWithoutMetadata
  dsos.each do |d|
    print_bitstream(d)
  end
  dsos.length
end

doit
