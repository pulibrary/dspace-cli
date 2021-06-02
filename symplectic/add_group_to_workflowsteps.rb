#!/usr/bin/env jruby

# add "all_groups_name" to all workflowsteps

require 'highline/import'
require 'dspace'
require 'cli/dcollection'
require 'cli/dconstants'

DSpace.load
DSpace.login DConstants::LOGIN
puts "\n"

com_name = 'All'
com = DSpace.findByMetadataValue('dc.title', com_name, DConstants::COMMUNITY)[0]
puts "no such community #{com_name}" unless com

all_groups_name = 'See_All_Submissions'
all_groups = DGroup.find(all_groups_name)
puts "no such group #{all_groups_name}" unless all_groups
puts "adding group #{all_groups.getName} to step 2 "
puts ''

com.getCollections.each do |col|
  dcol = DSpace.create(col)
  [2].each do |step|
    g = col.getWorkflowGroup(step)
    if g
      puts "#{col.getName} : #{g.getName}"
      g.addMember(all_groups)
      g.update
    else
      puts "#{col.getName} ******************"
    end
  end
end

doit = ask 'commit ? (Y/N) '
DSpace.commit if doit == 'Y'
