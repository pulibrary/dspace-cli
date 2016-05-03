#!/usr/bin/env jruby
require 'optparse'
require "highline/import"
require 'dspace'

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} source_col_handle destination_parent "
end

class Symplectic
  def self.submissions_reassign_destination(collection, col_candidates)
    java_import org.dspace.content.WorkspaceItem

    workflows = DWorkflowItem.findAll(collection)
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
              self.item_in_workflow_set_collection(flow, destination[0])
            end
          end
        end
      end
    end
  end

  def self.item_in_workflow_set_collection(flow, dest)
    java_import org.dspace.storage.rdbms.DatabaseManager

    sql = "UPDATE WORKFLOWITEM  SET COLLECTION_ID =  ? " +
        "WHERE  WORKFLOW_ID = ?";

    res = DatabaseManager.updateQuery(DSpace.context, sql, dest.getID, flow.getID)
    if (res == 1) then
      puts "WorkflowItem.#{flow.getID}, #{flow.item}: update destination collection to #{dest}:#{dest.getName}"
    else
      raise "WorkflowItem.#{flow.getID}, #{flow.item}: something went wrong updating destination collection: #{sql}"
    end
  end
end


if (false) then
  DSpace.load

  source_col = DSpace.fromString("COLLECTION.1")
  dest_com = DCommunity.all.select { |com| com.getName == "Repository" }[0]
  Symplectic.submissions_reassign_destination(source_col, dest_com.getCollections)

end


run = ARGV.shift
if (run == "run") then
  begin
    parser.parse!
    raise "must give at two handle parameters" if ARGV.length != 2
    DSpace.load
    source_col = DSpace.fromString(ARGV[0])
    dest_com = DSpace.fromString(ARGV[1])
    puts "reassigning items submitted to #{source_col.getName} to new collections in #{dest_com.getName}"
    Symplectic.submissions_reassign_destination(source_col, dest_com.getCollections)

    doit = ask "commit ? (Y/N) "
    if (doit == "Y") then
      DSpace.commit
    end
  rescue Exception => e
    puts e.message;
    puts parser.help();
  end
end
