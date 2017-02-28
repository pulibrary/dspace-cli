#!/usr/bin/env jruby 
require 'dspace'

DSpace.load

def print_active
  can = DEPerson.all.select { |p| p.canLogIn }
  print can.collect { |p| p.getEmail }.sort.join ", "
end

def print_all
  DEPerson.all.collect { |p| p.getEmail }.sort.each do |e|
    print_netid e, false
  end
end

def print_netid netid, groups
  p = DEPerson.find(netid)
  if (groups) then
    props = DSpace.create(p).groups.collect { |g| "GROUP.#{g.getName}" }
  else
    props = []
  end
  puts "EPERSON.#{p.getEmail}\t#{p.getNetid}\t" + props.join("\t")
end

