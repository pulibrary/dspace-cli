#!/usr/bin/env jruby

# Print all unarchived items and their workflow state to stdout

require 'dspace'
require 'cli/ditem.rb'
require 'symplectic/ditem.rb'

DSpace.load

def print_unarchived
  java_import org.dspace.workflow.WorkflowItem
  puts %w[ITEM-ID Symplectic-ID state worflow department title].join "\t"
  DItem.allUnarchived.each do |i|
    inflow = (WorkflowItem.findByItem(DSpace.context, i).nil? ? 'not in' : 'in') + ' workflow'
    dept = i.getMetadataFirstValue('pu', 'author', 'department', nil) || 'department-not-crosswalked'
    value = i.getMetadataFirstValue('pu', 'workflow', 'state', nil) || 'UNDEFINED'
    puts [i.toString, DSpace.create(i).symplecticID, "pu.workflow.state=#{value}", inflow, dept, i.getName].join "\t"
  end
end

print_unarchived
