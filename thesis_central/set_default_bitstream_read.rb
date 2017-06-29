require 'cli/dspace.rb'
DSpace.load

java_import org.dspace.eperson.Group


DSpace.login 'monikam'

def doit()
  mudd = Group.findByName(DSpace.context, 'SrTheses_Bitstream_Read_Mudd');

  com = DSpace.fromString('88435/dsp019c67wm88m')
  for col in com.getCollections
    p  =  get_policies(col, 9)[0]
    p.setGroup mudd
    p.update
  end
  DSpace.commit
  return col
end

def get_policies(b, action)
  java_import org.dspace.storage.rdbms.DatabaseManager
  java_import org.dspace.authorize.ResourcePolicy
  sql = "SELECT POLICY_ID FROM RESOURCEPOLICY WHERE  RESOURCE_ID = #{b.getID} AND RESOURCE_TYPE_ID = #{b.getType()} AND ACTION_ID = #{action}";
  tri = DatabaseManager.queryTable(DSpace.context, "RESOURCEPOLICY", sql)
  pols = []
  while (row = tri.next()) do
    p = ResourcePolicy.find(DSpace.context, row.getIntColumn("POLICY_ID"));
    puts p
    pols << p
  end
  tri.close()
  return pols
end

doit()