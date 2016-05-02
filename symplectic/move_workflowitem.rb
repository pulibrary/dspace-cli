#!/usr/bin/env jruby
require 'optparse'
require 'dspace'

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} handle.."
end

def item_in_workflow_set_collection(flow, dest)
  sql = "UPDATE WORKFLOWITEM  SET COLLECTION_ID =  ? " +
          "WHERE  WORKFLOW_ID = ?";

  res = DatabaseManager.updateQuery(DSpace.context, sql, dest.getID, flow.getID)
  if (res == 1) then
    puts "WorkflowItem.#{flow.getID}, #{flow.item}: update destination collection to #{dest}:#{dest.getName}"
  else
    raise "WorkflowItem.#{flow.getID}, #{flow.item}: something went wrong updating destination collection: #{sql}"
  end
end

def submissions_reassign_destination(collection, col_candidates)
  workflows = DSpace.create(collection).workflows
  workflows.each do |flow|
    item = flow.item
    # work only on items that are not owned and not part of a WorkspaceItem
    if (flow.owner.nil?) and WorkspaceItem.findByItem(DSpace.context, item).nil? then
      itemData = DSpace.create(item).getMetaDataValues
      groups = itemData.select { |f, v| f == "pubs.organisational-group" }.collect { |f, v| v }
      groups.each do |group|
        dest = group.split("/")[2]
        if dest then
          destination = col_candidates.select { |col| col.getName == dest }
          if (destination[0]) then
            item_in_workflow_set_collection(flow, destination[0])
          end
        end
      end
    end
  end
end


DSpace.load
java_import org.dspace.content.WorkspaceItem
java_import org.dspace.storage.rdbms.DatabaseManager

col_candidates = DCollection.all
collection = DSpace.fromString("COLLECTION.1")
workflows = DSpace.create(collection).workflows
flow = workflows[0]
item = flow.item
itemData = DSpace.create(flow.item).getMetaDataValues
groups = itemData.select { |f, v| f == "pubs.organisational-group" }.collect { |f, v| v }


submissions_reassign_destination(collection, col_candidates)
