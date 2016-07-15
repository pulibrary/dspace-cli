#!/usr/bin/env jruby
require 'dspace'
DSpace.load()

name = "Lib_DigPubs_Submitters"
DGroup.find(name).getMembers.each do |m|
    puts [name, m.getEmail, m.canLogIn ? "Can Login" : "can't Login", m.getFullName].join "\t\t"
end








