#!/usr/bin/env jruby -I lib
require "highline/import"
require 'dspace'

netid, first, last = ARGV
netid = ask("enter netid ") unless netid
first = ask("first name  ") unless first
last = ask("last name  ") unless last

admin = ENV["USER"]
puts "Logging in as: #{admin}"

doit = ask "create #{netid} for first_name: #{first} and last_name: #{last} ? (Y/N) "
if (doit == "Y") then
  DSpace.load
  DSpace.login(admin)

  p = DEperson.create(netid, first, last, netid + "@princeton.edu")
  doit = ask "commit ? (Y/N) "
  if (doit == "Y")
    DSpace.commit
  end
end 


