#!/usr/bin/env jruby  
require 'dspace'

DSpace.load

#postgres
# fromString = "COMMUNITY.145"

# dataspace

fromString = '88435/dsp019c67wm88m'

com = DSpace.fromString(fromString)
com.getCollections.collect do |col|
  g = col.getSubmitters()
  submitters = g ? g.getMembers : []
  puts "#{col.getName}\n\t#{submitters.collect { |s| s.getName }.join("\n\t")}"
end


