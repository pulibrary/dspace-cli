#!/usr/bin/env jruby -I lib
require 'optparse'
require 'dspace'

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__}   netid.."
end

netids = ARGV
if netids.empty? then
   parser.help
end

DSpace.load

netids.each do |netid| 
    p = DEperson.find(netid);
    if (p) then
      puts netid + ":"
      DSpace.create(p).group_names.each { |n| puts "\t#{n}"}
    else 
       puts "ERROR: EPERSON.#{netid} does not exist"
    end
   puts "";
end

