#!/usr/bin/env jruby 
require 'dspace'

DSpace.load

DEPerson.all.each do |p|
  props = DSpace.create(p).groups.collect { |g| "GROUP.#{g.getName}" }
  puts "EPERSON.#{p.getEmail}\t" + props.join("\t")
end