class DItem

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

  def index(force_update)
    java_import org.dspace.discovery.SolrServiceImpl
    idxService = DSpace.getIndexService()
    idxService.indexContent(DSpace.context, @obj, force_update)
  end
end