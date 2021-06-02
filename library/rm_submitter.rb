#!/usr/bin/env jruby
require 'dspace'
require 'highline/import'
require 'cli/dconstants'

# Command line wrapper for removeMember method, specific to the Submitters handle.

DSpace.load
DSpace.context_renew

name = DConstants::SUBMITTERS_NAME
group = DGroup.find(name)

loop do
  netid = ask 'Netid of person to remove / or blank to exit> '
  if netid != ''
    m = DEPerson.find(netid)
    if m
      puts ['removing', name, m.getEmail, m.canLogIn ? 'Can Login' : "Can't Login", m.getFullName].join "\t\t"
      group.removeMember(m)
    else
      puts 'no such eperson'
    end
  else
    break
  end
end

yes = ask 'Commit ? (Y/N)'
if yes[0] == 'Y'
  DSpace.login DConstants::LOGIN
  group.update
  DSpace.commit
end
