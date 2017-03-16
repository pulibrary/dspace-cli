#!/usr/bin/env jruby
require "highline/import"
require 'dspace'
require 'symplectic/ditem'

DSpace.load
DSpace.context_renew
DSpace.login ENV['USER']



def doit(title)
  item = get_item title
  if item.nil?
    puts " no such item on the repo/workflow  ..."
  else
    puts [item.getID, "archived:", item.isArchived, item.getName].join("\t")
    di = DSpace.create(item)
    di.retract
    y = ask("commit changes ? (yes/no) ")
    if (y == 'yes')
      DSpace.commit
    end
  end
end

def get_item(title)
  items = DSpace.findByMetadataValue('dc.title', title, DConstants::ITEM)
  return items[0]
end

class DItem
  java_import org.dspace.storage.rdbms.DatabaseManager

  def retract()
    unless dso.nil?
      raise "can't retract archived item" if dso.isArchived
      sql = "DELETE SYMPLECTIC_PIDS WHERE ITEM_ID = ?"
      tri = DatabaseManager.updateQuery(DSpace.context, sql, dso.getID)
      puts tri
      wflows = DWorkflowItem.findAll(dso)
      wflows.each do |wf|
        wf.deleteWrapper
      end
      dso.delete
    end
  end

end


# title = "A Transport Model for Estimating the Time Course of ERK Activation in the C%"
puts "do not include speacial character in the title"
title = ask("title ") unless title
puts "Title: " + title
doit title
