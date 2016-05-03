#!/usr/bin/env jruby
require 'optparse'
require "highline/import"
require 'dspace'
require 'cli/dcommunity'

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} community file_with_collection_names"
end

begin
  parser.parse!
  raise "must give community and file name" if ARGV.length != 2

  com_name = ARGV[0]
  name_file = File.new(ARGV[1], "r")

  DSpace.load
  DSpace.login ENV['USER']
  com = DSpace.create(DSpace.fromString(com_name))
  name_file.readlines.each do |name|
    col = com.find_or_create_collection_by_name(name.strip)
    puts "collection #{col.getName}\tin  #{DSpace.create(col).parents.collect { |p| p.getName }}"
  end

  doit = ask "commit ? (Y/N) "
  if (doit == "Y") then
    DSpace.commit
  end

rescue Exception => e
  puts e.message;
  puts parser.help();
end
