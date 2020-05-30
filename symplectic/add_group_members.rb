#!/usr/bin/env jruby

# Given a text file modeled after group_members.txt, add the given person to the 
#   given group. Follow the prompts to confirm.

require "highline/import"
require 'dspace'
require 'cli/dconstants'

DSpace.load
DSpace.login DConstants::LOGIN
puts "\n"

filename = 'symplectic/group_members.txt'
puts "reading group memberships from #{filename}"

f = File.open(filename, "r")
f.each_line do |line|
  group_name, email = line.chop.split(',')
  #puts [group_name, email].join "\t"
  group = DGroup.find(group_name)
  puts "no such group #{group_name}" unless group
  person = DEPerson.find(email)
  puts "no such person #{email}" unless person
  if (group and person)
    if group.isMember(person)
      puts "#{person.getEmail} member of #{group.getName} "
    else
      puts "#{person.getEmail} add to #{group.getName} "
      group.addMember(person)
      group.update
    end
  end
end

doit = ask "commit ? (Y/N) "
if (doit == "Y") then
  DSpace.commit
end
