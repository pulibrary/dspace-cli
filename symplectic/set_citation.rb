#!/usr/bin/env jruby
require "highline/import"
require 'dspace'

def set_inworkflow(value, mod = 1)
  DWorkflowItem.findAll(nil).each do |flow|
    if (0 == flow.getID % mod) then
      i = flow.getItem
      i.setMetadataSingleValue('pu', 'workflow', 'state', nil, value)
      i.update
      dept = i.getMetadataFirstValue('pu', 'author', 'department', nil) || 'department-not-crosswalked'
      puts [flow.getID, i.toString, "pu.workflow.state=#{value}", dept, i.getName].join "\t   "
    end
  end
end

def unset_inworkflow(mod = 1)
  DWorkflowItem.findAll(nil).each do |flow|
    if (0 == flow.getID % mod) then
      i = flow.getItem
      i.clearMetadata('pu', 'workflow', 'state', nil)
      i.update
      dept = i.getMetadataFirstValue('pu', 'author', 'department', nil) || 'department-not-crosswalked'
      puts [flow.getID, i.toString, "clear pu.workflow.state", dept, i.getName].join "\t   "
    end
  end
end

def set_orphaned(value)
  DItem.allUnarchived.each do |i|
    flow = WorkflowItem.findByItem(DSpace.context, i)
    if (flow.nil?) then
      i.setMetadataSingleValue('pu', 'workflow', 'state', nil, value)
      i.update
      dept = i.getMetadataFirstValue('pu', 'author', 'department', nil) || 'department-not-crosswalked'
      puts [i.toString, "pu.workflow.state=#{value}" ,dept, i.getName].join "\t   "
    end
  end
end

