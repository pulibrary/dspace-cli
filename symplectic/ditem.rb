require 'dspace'

class DItem

  def symplecticID
    java_import org.dspace.storage.rdbms.DatabaseManager
    sql = "SELECT PID FROM SYMPLECTIC_PIDS WHERE ITEM_ID = #{@obj.getID}";
    tri = DatabaseManager.queryTable(DSpace.context, "SYMPLECTIC_PIDS", sql)
    n =  tri.next()
    (n.nil?) ? nil : n.getStringColumn("PID")
  end

  # Find an item when given its symplectic ID
  def self.findBySymplecticId sid
    java_import org.dspace.storage.rdbms.DatabaseManager
    sql = "SELECT ITEM_ID FROM SYMPLECTIC_PIDS WHERE PID = #{sid}";
    tri = DatabaseManager.queryTable(DSpace.context, "SYMPLECTIC_PIDS", sql)
    item_id = tri.next().getIntColumn("ITEM_ID")
    puts item_id
    DItem.find(item_id)
  end

end