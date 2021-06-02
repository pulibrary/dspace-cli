#!/usr/bin/env jruby

# Print tab-separated values of all submitters

require 'dspace'
require 'cli/dconstants'

DSpace.load

name = DConstants::SUBMITTERS_NAME
DGroup.find(name).getMembers.each do |m|
  puts [name, m.getEmail, m.canLogIn ? 'Can Login' : "Can't Login", m.getFullName].join "\t\t"
end
