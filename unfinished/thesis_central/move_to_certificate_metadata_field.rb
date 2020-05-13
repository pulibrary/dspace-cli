# UNFINISHED
# 
# This script was left as plaintext, and it's not prepared for general use. 

require 'dspace'
require 'cli'

DSpace.load

cwr = 'Creative Writing Program'
print cwr
print 'Theater'

java_import org.dspace.storage.rdbms.DatabaseManager

def move_to_certficate_field(value)

  deptField = f = DMetadataField.find('pu.department')
  certField = f = DMetadataField.find('pu.certificate')

  puts certField.getFieldID

  # SELECT metadata_value_id,  resource_id, resource_type_id, text_value FROM METADATAVALUE where metadata_field_id= 162  and TEXT_VALUE LIKE 'Creative Writing Program';

  sql = "SELECT metadata_value_id,  resource_id, resource_type_id, text_value FROM METADATAVALUE ";
  sql = sql + " where metadata_field_id= #{deptField.getFieldID} "
  sql = sql + " and text_value LIKE '#{value}' "
  sql = sql + " and resource_type_id=2 "
  puts sql

  tri = DatabaseManager.queryTable(DSpace.context, "MetadataValue", sql)
  while (iter = tri.next())
    item = DItem.find iter.getIntColumn('resource_id')
    updsql = "UPDATE METADATAVALUE SET METADATA_FIELD_ID = '342' "
    updsql = updsql + " where metadata_value_id= #{iter.getIntColumn("metadata_value_id")} ";
    puts ['#', updsql].join "\t"
    res = DatabaseManager.updateQuery(DSpace.context, updsql)
    puts ['#', "RES=#{res}", item.getHandle, iter.getIntColumn('resource_type_id'), iter.getIntColumn("metadata_value_id"), iter.getStringColumn("text_value")].join "\t"
  end
  tri.close
  puts "commit changes if everuting is good ..."
end

