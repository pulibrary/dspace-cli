#!/usr/bin/env jruby 
require 'dspace'

DSpace.load

def print_all
  DEPerson.all.each do |p|
    pprint_netid p.getNetid
  end
end

def print_netid netid
  p = DEPerson.find(netid)
  props = DSpace.create(p).groups.collect { |g| "GROUP.#{g.getName}" }
  puts "EPERSON.#{p.getEmail}\t" + props.join("\t")
end