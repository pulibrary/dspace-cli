#!/usr/bin/env jruby

# Apply the naming standardizing functions to each handle provided by the command line

require 'optparse'
require "highline/import"
require 'dspace'
require 'cli/dcommunity'
require 'cli/dcollection'

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} handle.."
end


begin
  parser.parse!
  raise "must give at least one collection/community parameter" if ARGV.empty?

  DSpace.load

  ARGV.each do |str|
    dso = DSpace.fromString(str)
    DSpace.create(dso).name_submitter_group.name_workflow_groups
  end

  doit = ask "commit ? (Y/N) "
  if (doit == "Y") then
    DSpace.commit
  end

rescue Exception => e
  puts e.message;
  puts parser.help();
end
