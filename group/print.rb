#!/usr/bin/env jruby
require 'dspace'

DSpace.load

def print_all
  DGroup.all.each do |p|
    print_group g.getName
  end
end

def print_group name
  g = DGroup.find(name)
  unless g.nil? then
    members = DSpace.create(g).members
    puts g.getName
    members.each do |m|
      fullName = ''
      fullName = m.fullName if m.respond_to? 'fullName'
      puts ["", m.getName, fullName].join("\t")
    end
  end
end