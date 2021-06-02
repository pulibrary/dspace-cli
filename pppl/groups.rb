# Print out Submitters and users in workflow steps for all of PPPL

require 'irb/completion'
require 'dspace'
require 'cli/dconstants'

DSpace.load

hdl = DConstants::PPPL_HANDLE

# recursively get all members from within a group and subgroups
def rec_members(group)
  gmems = group.getMemberGroups
  mems = gmems.collect { |g| g} + group.getMembers.collect { |m| m}
  for g in gmems do
    mems += rec_members(g)
  end
  mems
end

# Print out Submitters and users in workflow steps for all of PPPL
def doit(hdl)
  root = DSpace.fromString(hdl)
  colls = root.getAllCollections
  puts '-- SUBMITTERS'
  for c in colls do
    submitters = DSpace.create(c.getSubmitters).members
    mems = rec_members(submitters[0]) << submitters[0]
    puts([c.getName, 'SUBMITTERS', mems.collect { |s| s.getName }.sort].join("\t"))
  end
  for stp in [1, 2, 3] do
    puts ''
    puts "-- STEP #{stp}"
    for c in colls do
      group = c.getWorkflowGroup(stp)
      if group
        mems = rec_members(group)
        puts([c.getName, "STEP #{stp}", mems.collect { |s| s.getName }.sort].join("\t"))
      end
  end
  end
end

doit(hdl)
