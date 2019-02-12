#!/usr/bin/env jruby 
require "highline/import"

netid = 'monikam';
name = ask "Collection Name "; 
name = name.strip;

parent = '88435/dsp019c67wm88m'

require 'dspace'
DSpace.load()

puts "Name:\n\t#{name}";

parent_col = DSpace.fromString(parent)
puts "Parent:\n\t#{parent_col.getName}";

item_reader = DSpace.fromString("Group.SrTheses_Item_Read_Anonymous");
puts "ItemRead:\n\t#{item_reader.getName}";

bitstream_read = DSpace.fromString("Group.SrTheses_Bitstream_Read_Mudd")
puts "BitstreamRead:\n\t#{bitstream_read.getName}";

item_add = DSpace.fromString("Group.SrTheses_Approvers");
puts "ItemAdd:\n\t#{item_add.getName}";

approvers = DSpace.fromString("Group.SrTheses_Approvers");
puts "Approvers:\n\t#{approvers.getName}";


def get_policies(b, action)
    puts "get_policies #{action}"
    java_import org.dspace.storage.rdbms.DatabaseManager
    java_import org.dspace.authorize.ResourcePolicy
    sql = "SELECT POLICY_ID FROM RESOURCEPOLICY WHERE  RESOURCE_ID = #{b.getID} AND RESOURCE_TYPE_ID = #{b.getType()} AND ACTION_ID = #{action}";
    tri = DatabaseManager.queryTable(DSpace.context, "RESOURCEPOLICY", sql)
    pols = []
    while (row = tri.next()) do
        p = ResourcePolicy.find(DSpace.context, row.getIntColumn("POLICY_ID"));
        pols << p
    end
    tri.close()
    if pols.empty? then
        myPolicy = ResourcePolicy.create(DSpace.context);
        myPolicy.setResource(b);
        myPolicy.setAction(action);
        pols << myPolicy
    end
    puts pols.empty?
    return pols
end

yes = ask "do you want to create ? [Y/N] "
if (yes[0] == 'Y' || TRUE) then
    DSpace.login(netid)

    new_col = DCollection.create(name, parent_col)
    puts "created\t\t#{new_col.getName()} in #{parent_col.getName()}}"

    pol = get_policies(new_col, DConstants::DEFAULT_ITEM_READ)[0];
    pol.setGroup item_reader
    pol.update
    puts pol

    pol = get_policies(new_col, DConstants::DEFAULT_BITSTREAM_READ)[0];
    pol.setGroup bitstream_read
    pol.update
    puts pol

    pol = get_policies(new_col, DConstants::ADD)[0];
    pol.setGroup item_add
    pol.update
    puts pol

    new_col.setWorkflowGroup(3, approvers)
    new_col.update


    DSpace.commit
    puts "Committed #{new_col.getHandle()}"

end

