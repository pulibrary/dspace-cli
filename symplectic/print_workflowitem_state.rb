#!/usr/bin/env jruby
require "highline/import"
require 'dspace'

def print_unarchived
  DItem.allUnarchived.each do |i|
    inflow = (WorkflowItem.findByItem(DSpace.context, i).nil? ? "not in" : "in") + " workflow"
    dept = i.getMetadataFirstValue('pu', 'author', 'department', nil) || 'department-not-crosswalked'
    value = i.getMetadataFirstValue('pu', 'workflow', 'state', nil) || 'UNDEFINED'
    puts [i.toString, "pu.workflow.state=#{value}", inflow, dept, i.getName].join "\t"
  end
end

print_unarchived