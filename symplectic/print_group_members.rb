#!/usr/bin/env jruby

# print members and member groups to stdout
# TODO: This is not unique to Symplectic and the functionality should be moved

require "highline/import"
require 'dspace'

DSpace.load
puts "\n"

# print out members
puts ["Group    ", "Account Member's Email"].join("\t")
DGroup.all.collect { |g| g.getName }.sort.each do |group_name|
  group = DGroup.find(group_name)
  group.getMembers.each do |member|
    puts [group.getName, member.getEmail].join("\t")
  end
end
puts ""

# print out member groups
puts ["Group   ", "Member's Group Name"].join("\t")
DGroup.all.collect { |g| g.getName }.sort.each do |group_name|
  group = DGroup.find(group_name)
  group.getMemberGroups.each do |member|
    puts [group.getName, member.getName].join("\t")
  end
end
