require 'dspace'

# Class decorating org.dspace.content.Item objects interfacing with Symplectic Elements
# @see https://github.com/DSpace/DSpace/blob/dspace-5.3/dspace-api/src/main/java/org/dspace/content/Item.java
class DItem

  # Query for and return the internal Symplectic Elements publication ID (PID) associated with the decoroated DSpaceObject ID
  # @return [String]
  def symplecticID
    java_import org.dspace.storage.rdbms.DatabaseManager
    sql = "SELECT PID FROM SYMPLECTIC_PIDS WHERE ITEM_ID = #{@obj.getID}";
    tri = DatabaseManager.queryTable(DSpace.context, "SYMPLECTIC_PIDS", sql)
    n =  tri.next()
    (n.nil?) ? nil : n.getStringColumn("PID")
  end

  # Find a DSpaceObject ID using an associated Symplectic Elements publication ID
  # @param sid [String] the Symplectic Elements publication ID
  # @return [org.dspace.content.Item]
  def self.findBySymplecticId sid
    java_import org.dspace.storage.rdbms.DatabaseManager
    sql = "SELECT ITEM_ID FROM SYMPLECTIC_PIDS WHERE PID = #{sid}";
    tri = DatabaseManager.queryTable(DSpace.context, "SYMPLECTIC_PIDS", sql)
    item_id = tri.next().getIntColumn("ITEM_ID")
    puts item_id
    DItem.find(item_id)
  end

end
