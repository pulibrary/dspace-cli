# Class modeling procedures for org.dspace.content.Item objects
# @see https://github.com/DSpace/DSpace/blob/dspace-5.3/dspace-api/src/main/java/org/dspace/content/Item.java
class DItem

  # Retrieve all DSpace items which have not been fully ingested into the system
  # @return [Array<org.dspace.content.DSpaceObject>]
  def self.allUnarchived
    java_import org.dspace.storage.rdbms.DatabaseManager

    sql = "SELECT item_id FROM ITEM WHERE in_archive<>'1'";
    tri = DatabaseManager.queryTable(DSpace.context, "Item", sql)
    dsos = [];
    while (iter = tri.next())
      dsos << self.find(iter.getIntColumn("item_id"))
    end
    tri.close
    return dsos
  end

  # Forces the Solr discovery service to reindex a DSpace Object
  # @see https://github.com/DSpace/DSpace/blob/dspace-5.3/dspace-api/src/main/java/org/dspace/discovery/SolrServiceImpl.java#L201
  # @param force_update [Boolean] whether or not to overwrite an existing Solr entry for the object
  def index(force_update)
    java_import org.dspace.discovery.SolrServiceImpl
    idxService = DSpace.getIndexService()
    idxService.indexContent(DSpace.context, @obj, force_update)
  end
end
