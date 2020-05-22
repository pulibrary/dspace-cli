#!/usr/bin/env jruby

# Add standardized workflow steps to all collections

require "highline/import"
require 'dspace'
require 'cli/dcollection'
require 'cli/dconstants'

DSpace.load
DSpace.login DConstants::LOGIN
puts "\n"

com_name =  'All Content'
com = DSpace.findByMetadataValue('dc.title', com_name, DConstants::COMMUNITY)[0]
puts "no such community #{com_name}" unless com

all_groups_name = 'See_All_Tasks'
all_groups = DGroup.find(all_groups_name)
puts "no such group #{all_groups_name}" unless all_groups
puts "adding workflows steps 2,3 to collections in #{com.getName} #{com.getHandle}"
puts "adding group #{all_groups.getName} to step 2,3 "
puts ""

com.getCollections.each do |col|
  dcol = DSpace.create(col)
  [2, 3].each do |step|
    g = dcol.find_or_create_workflow_group("step_#{step}")
    puts "#{col.getName} : #{g.getName}"
    g.addMember(all_groups)
    g.update
  end
end

doit = ask "commit ? (Y/N) "
if (doit == "Y") then
  DSpace.commit
end