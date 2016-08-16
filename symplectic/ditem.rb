require 'dspace'

class DItem

  def symplecticID
    java_import org.dspace.storage.rdbms.DatabaseManager
    sql = "SELECT PID FROM SYMPLECTIC_PIDS WHERE ITEM_ID = #{@obj.getID}";
    tri = DatabaseManager.queryTable(DSpace.context, "SYMPLECTIC_PIDS", sql)
    return tri.next().getStringColumn("PID")
  end

end