#!/usr/bin/env jruby  

# print all senior thesis submitters

require 'dspace'
require 'cli/dconstants'

DSpace.load

#postgres
# fromString = "COMMUNITY.145"

# dataspace

fromString = DConstants::SENIOR_THESIS_HANDLE

com = DSpace.fromString(fromString)
com.getCollections.collect do |col|
  g = col.getSubmitters()
  submitters = g ? g.getMembers : []
  puts "#{col.getName}\n\t#{submitters.collect { |s| s.getName }.join("\n\t")}"
end


