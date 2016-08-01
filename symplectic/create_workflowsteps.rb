#!/usr/bin/env jruby
require "highline/import"
require 'dspace'

DSpace.load
DSpace.login ENV['USER']

filename = 'symplectic/departments.txt'
puts "reading collections from #{filename}"
com = DSpace.findByMetadataValue('dc.title', 'All Content', DConstants::COMMUNITY)[0]
puts "adding collections to #{com.getName} #{com.getHandle}"

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