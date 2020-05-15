#!/usr/bin/env jruby 
require "highline/import"
require 'cli/dconstants'
require 'dspace'

netid, first, last = ARGV
netid = ask("enter netid ") unless netid
first = ask("first name  ") unless first
last = ask("last name  ") unless last

admin = DConstants::LOGIN
puts "Logging in as: #{admin}"

DSpace.load
DSpace.login(admin)
p = DEPerson.create(netid, first, last, netid + "@princeton.edu")
puts "Create    #{[p.getNetid, p.getFullName, p.getEmail].join(", ")} ?"
if "Y" ==  ask("Yes or No (Y/N) ") then
  DSpace.commit
else
  DSpace.context_renew
end


