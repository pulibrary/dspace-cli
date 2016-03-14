#!/usr/bin/env jruby -I lib
require "highline/import"
require 'dspace'

netid, pwd = ARGV

if (netid.nil?) then
    netid = ask "enter netid "
end

DSpace.load
DSpace.login(ENV['USER']) 

p = DEperson.find(netid);
raise "no such eperson" if p.nil?

if (pwd.nil?) then
    pwd = ask "enter password "
end

p.setPassword(pwd) 
p.update
DSpace.commit



