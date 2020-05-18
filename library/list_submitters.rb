#!/usr/bin/env jruby
require 'dspace'
require 'cli/dconstants'

DSpace.load()

name = DConstants::SUBMITTERS_NAME
DGroup.find(name).getMembers.each do |m|
    puts [name, m.getEmail, m.canLogIn ? "Can Login" : "can't Login", m.getFullName].join "\t\t"
end








