#!/usr/bin/env jruby

# Reset password of given netid

require 'highline/import'
require 'dspace'
require 'cli/dconstants'

netid, pwd = ARGV

netid = ask 'enter netid ' if netid.nil?

DSpace.load
DSpace.login DConstants::LOGIN

p = DEPerson.find(netid)
raise 'no such eperson' if p.nil?

pwd = ask 'enter password ' if pwd.nil?

p.setPassword(pwd)
p.update
DSpace.commit
