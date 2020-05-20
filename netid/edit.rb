#!/usr/bin/env jruby 

# This is a complicated script that walks you through either adding 
#   a given netid to the same groups as another user, or removing a user from
#   a group.

require "highline/import"
require 'dspace'

netid, who = ARGV

if (netid.nil?) then
  netid = ask "enter netid "
end

DSpace.load

# TODO: This naming convention is misleading. This prints the groups of which
#   the given person is a member.
def print_members(p)
  puts p.getNetid + ":"
  DSpace.create(p).groups.each { |g| puts "\t#{g.getName}" }
end

p = DEPerson.find(netid);
raise "no such eperson" if p.nil?
print_members(p);

if (who.nil?) then
  who = ask "want to add to same groups as another user ? [return/netid] "
end

unless (who.empty?) then
  o = DEPerson.find(who);
  raise "no such eperson" if o.nil?
  print_members(o);
  pgroups = DSpace.create(p).groups
  DSpace.create(o).groups.each do |g|
    if (pgroups.select { |pg| pg.getName() == g.getName }.empty?) then
      yes = ask "add #{p} to #{g.getName()} ? [Y/N] ";
      if (yes == "Y") then
        puts "\tadding #{p} to #{g}"
        g.addMember(p);
        g.update();
      end
    else
      puts "\talready member of GROUP.#{g.getName}"
    end
  end
end
puts "";

if "Y" == ask("want to remove from groups ? [Y/N] ") then
  DSpace.create(p).groups.each do |g|
    yes = ask "remove #{p} from #{g.getName()} ? [Y/N] ";
    if (yes == "Y") then
      puts "\tremoving from #{g}"
      g.removeMember(p);
      g.update();
    end
  end
end
puts "";

print_members(p);
if "Y" == ask("want to commit the changes ? [Y/N] ") then
  DSpace.commit
end
