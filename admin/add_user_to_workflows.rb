require 'dspace'
require "highline/import"


DSpace.load
DSpace.login ENV["USER"]

def doit_add_to_all_workflows
  p = get_user
  sql = "SELECT workflow_id,item_id from workflowitem WHERE workflow_id not in (SELECT workflow_id FROM TASKLISTITEM WHERE eperson_id = #{p.getID()})"
  puts sql
  tri = DatabaseManager.queryTable(DSpace.context, "workflowitem", sql)
  create_tasks p, tri
  commit?
end

def doit_add_to_coll_workflows
  coll = get_collection
  p = get_user
  flows =  DWorkflowItem.findAll(coll )
  for f in flows do
    # this may create duplicate tasks for the same workflow
    create_task(p.getID, f.getID, f.getItem.getID)
  end
  commit?
end

def get_user
  netid = ask("Netid ? ")
  p = DEPerson.find(netid)
  if not p then
    raise "no such account #{netid}"
  end
  return p
end

def get_collection
  hdl = ask("Collection Handle  ? ")
  coll = DSpace.fromString(hdl)
  if not coll then
    raise "no such collection #{hdl}"
  end
  return coll
end

def commit?
  if "Y" == ask("Commit changes: Yes or No (Y/N) ") then
    DSpace.commit
  else
    DSpace.context_renew
  end
end

def create_tasks(p, tri)
  while (n = tri.next())
    wid = n.getIntColumn('workflow_id')
    item_id = n.getIntColumn('item_id')
    create_task p.getID, wid, item_id
  end
  nil
end

def create_task(pid, wid, item_id)
  java_import org.dspace.storage.rdbms.DatabaseManager

  row = DatabaseManager.row("tasklistitem")
  row.setColumn("eperson_id", pid)
  i = DItem.find(item_id)
  puts "#{wid}\t#{i.getName}"
  row.setColumn("workflow_id", wid)
  DatabaseManager.insert(DSpace.context, row)
end

#doit_add_to_coll_workflow#
doit_add_to_coll_workflows
