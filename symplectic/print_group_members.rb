#!/usr/bin/env jruby
require "highline/import"
require 'dspace'

DSpace.load
puts "\n"

puts ["Group    ", "Account Member's Email"].join("\t")
DGroup.all.collect { |g| g.getName }.sort.each do |group_name|
  group = DGroup.find(group_name)
  group.getMembers.each do |member|
    puts [group.getName, member.getEmail].join("\t")
  end
end
puts ""

puts ["Group   ", "Member's Group Name"].join("\t")
DGroup.all.collect { |g| g.getName }.sort.each do |group_name|
  group = DGroup.find(group_name)
  group.getMemberGroups.each do |member|
    puts [group.getName, member.getName].join("\t")
  end
end
