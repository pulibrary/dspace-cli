#!/usr/bin/env jruby
require "highline/import"
require 'dspace'

DSpace.load
DSpace.login ENV['USER']
puts "\n"


DGroup.all.each do |group|
  group.getMembers.each do |person|
    puts [group.getName, person.getEmail].join(",")
  end
end
