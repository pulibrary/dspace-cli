##
# This class extends DItem from the dspace jruby gem for Princeton-specific
# functionality.
# @see https://github.com/pulibrary/dspace-jruby
class DItem

  # Search the entire DSpace context for Items that are not archived and return
  #   a list of Items
  def self.allUnarchived
    java_import org.dspace.storage.rdbms.DatabaseManager

    # Get item ids where in_archive (boolean) not equal to 1 (true)
    sql = "SELECT item_id FROM ITEM WHERE in_archive<>'1'";
    tri = DatabaseManager.queryTable(DSpace.context, "Item", sql)
    dsos = [];
    while (iter = tri.next())
      dsos << self.find(iter.getIntColumn("item_id"))
    end
    tri.close
    return dsos
  end

  # index the DItem, force_update is a boolean
  # @see https://github.com/DSpace/DSpace/blob/dspace-5_x/dspace-api/src/main/java/org/dspace/discovery/SolrServiceImpl.java
  def index(force_update)
    java_import org.dspace.discovery.SolrServiceImpl # TODO: Delete this unnecessary line
    idxService = DSpace.getIndexService()
    idxService.indexContent(DSpace.context, @obj, force_update)
  end
end