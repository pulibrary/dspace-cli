#!/usr/bin/env jruby
require 'optparse'
require "highline/import"
require 'dspace'
require 'cli/dcommunity'
require 'cli/dcollection'
require 'cli/dconstants'

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} handle (step_1, step_2, step_3, submit)*"
end

begin
  parser.parse!
  raise "must give at collection/community parameter and at least one workflow step" if ARGV.length < 2

  DSpace.load
  DSpace.login DConstants::LOGIN
  handle = ARGV.shift
  dso = DSpace.create(DSpace.fromString(handle))
  ARGV.each do |step|
    dso.find_or_create_workflow_group(step)
  end

  doit = ask "commit ? (Y/N) "
  if (doit == "Y") then
    DSpace.commit
  end

rescue Exception => e
  puts e.message;
  puts parser.help();
end
