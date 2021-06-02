#!/usr/bin/env jruby

# A command-line wrapper for the DEPerson's create method, unique to Princeton

require 'highline/import'
require 'cli/dconstants'
require 'dspace'

netid, first, last = ARGV
netid ||= ask('enter netid ')
first ||= ask('first name  ')
last ||= ask('last name  ')

admin = DConstants::LOGIN
puts "Logging in as: #{admin}"

DSpace.load
DSpace.login(admin)
p = DEPerson.create(netid, first, last, netid + '@princeton.edu')
puts "Create    #{[p.getNetid, p.getFullName, p.getEmail].join(', ')} ?"
if 'Y' == ask('Yes or No (Y/N) ')
  DSpace.commit
else
  DSpace.context_renew
end
