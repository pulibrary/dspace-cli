#!/usr/bin/env jruby
require "highline/import"
require 'dspace'
require 'cli/dconstants'

DSpace.load
DSpace.login DConstants::LOGIN
puts "\n"

com_name =  'All'
com = DSpace.findByMetadataValue('dc.title', com_name, DConstants::COMMUNITY)[0]
puts "no such community #{com_name}" unless com
puts "adding collections to #{com.getName} #{com.getHandle}"

filename = 'symplectic/departments.txt'
puts "reading collections from #{filename}"

collNames = com.getCollections.collect { |c| c.getName }

f = File.open(filename, "r")
f.each_line do |name|
  name = name.chop
  if  collNames.include?(name)
    puts "exists #{name}"
  else
    puts "CREATE #{name}"
    DCollection.create(name, com)
  end
end


doit = ask "commit ? (Y/N) "
if (doit == "Y") then
  DSpace.commit
end