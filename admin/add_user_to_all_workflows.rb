require 'dspace'
require "highline/import"
require 'cli/dconstants'


DSpace.load

def doit
  puts "\nadd user to ALL workflows"
  netid = ask("Netid ? ")

  p = DEPerson.find(netid)

  if not p then
    puts "no such account #{netid}"
  else
    DSpace.login DConstants::LOGIN
    create_tasks p
    if "Y" == ask( "Commit changes: Yes or No (Y/N) ") then
      DSpace.commit
    else
      DSpace.context_renew
    end
  end
  doit

end

def create_tasks(p)
  java_import org.dspace.storage.rdbms.DatabaseManager
  java_import org.dspace.workflow.WorkflowManager
  java_import org.dspace.storage.rdbms.TableRow

  sql = "SELECT workflow_id,item_id from workflowitem WHERE workflow_id not in (SELECT workflow_id FROM TASKLISTITEM WHERE eperson_id = #{p.getID()})"
  puts sql
  tri = DatabaseManager.queryTable(DSpace.context, "workflowitem", sql)
  row = DatabaseManager.row("tasklistitem")
  row.setColumn("eperson_id", p.getID())
  while (n = tri.next())
    wid = n.getIntColumn('workflow_id')
    item_id = n.getIntColumn('item_id')
    i  = DItem.find(item_id)
    puts "#{wid}\t#{i.getName}"
    row.setColumn("workflow_id", wid)
    DatabaseManager.insert(DSpace.context, row)
  end
  nil
end




doit
