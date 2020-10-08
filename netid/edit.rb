#!/usr/bin/env jruby

# This is a complicated script that walks you through either adding
#   a given netid to the same groups as another user, or removing a user from
#   a group.

require 'highline/import'
require 'dspace'

netid, who = ARGV

netid = ask 'enter netid ' if netid.nil?

DSpace.load

# TODO: This naming convention is misleading. This prints the groups of which
#   the given person is a member.
def print_members(p)
  puts p.getNetid + ':'
  DSpace.create(p).groups.each { |g| puts "\t#{g.getName}" }
end

p = DEPerson.find(netid)
raise 'no such eperson' if p.nil?

print_members(p)

who = ask 'want to add to same groups as another user ? [return/netid] ' if who.nil?

unless who.empty?
  o = DEPerson.find(who)
  raise 'no such eperson' if o.nil?

  print_members(o)
  pgroups = DSpace.create(p).groups
  DSpace.create(o).groups.each do |g|
    if pgroups.select { |pg| pg.getName == g.getName }.empty?
      yes = ask "add #{p} to #{g.getName} ? [Y/N] "
      if yes == 'Y'
        puts "\tadding #{p} to #{g}"
        g.addMember(p)
        g.update
      end
    else
      puts "\talready member of GROUP.#{g.getName}"
    end
  end
end
puts ''

if 'Y' == ask('want to remove from groups ? [Y/N] ')
  DSpace.create(p).groups.each do |g|
    yes = ask "remove #{p} from #{g.getName} ? [Y/N] "
    next unless yes == 'Y'

    puts "\tremoving from #{g}"
    g.removeMember(p)
    g.update
  end
end
puts ''

print_members(p)
DSpace.commit if 'Y' == ask('want to commit the changes ? [Y/N] ')
