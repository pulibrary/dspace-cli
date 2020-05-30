#!/usr/bin/env jruby

# Create all accounts listed in accounts.txt
# TODO: Remove this file and add this functionality to netid directory (or DPerson class)

require "highline/import"
require 'dspace'

require 'cli/dconstants'

DSpace.load
DSpace.login DConstants::LOGIN
puts "\n"

filename = 'symplectic/accounts.txt'
puts "reading accounts from #{filename}"

f = File.open(filename, "r")
f.each_line do |line|
  netid, first, last = line.chop.split
  #puts ['netid', netid, 'first', first, 'last', last].join "\t"
  if DEPerson.find(netid)
    puts "exists #{netid}"
  else
    p = DEPerson.create(netid, first, last, netid + "@princeton.edu")
    puts "created #{p.getEmail}  #{p.getFullName}"
  end
end

doit = ask "commit ? (Y/N) "
if (doit == "Y") then
  DSpace.commit
end
