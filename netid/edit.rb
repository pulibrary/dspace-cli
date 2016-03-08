#!/usr/bin/env jruby -I lib
require "highline/import"
require 'dspace'

netid, who = ARGV

if (netid.nil?) then
    netid = ask "enter netid "
end

DSpace.load

def print_members(p)
  puts p.getNetid + ":"
  DSpace.create(p).group_names.each { |n| puts "\t#{n}"}
end

p = DEperson.find(netid);
raise "no such eperson" if p.nil?
print_members(p);

if (who.nil?) then
    who = ask "want to add to same groups as another user ? [return/netid] "
end

  o = DEperson.find(who);
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
      puts "\talready member of #{g}"
    end
  end

puts "";


yes = ask "want to remove from groups ? [Y/N] "
if (yes == "Y") then
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
yes = ask "want to commit the changes ? [Y/N] "
if (yes == "Y") then
  DSpace.commit
end
