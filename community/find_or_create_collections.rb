#!/usr/bin/env jruby
require 'optparse'
require "highline/import"
require 'dspace'
require 'cli/dcommunity'
require 'cli/dconstants'

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} community file_with_collection_names"
end

def create_collections(com, file_name)
  name_file = File.new(file_name, "r")
  dcom = DSpace.create(com)
  name_file.readlines.each do |name|
    col = dcom.find_or_create_collection_by_name(name.strip)
    puts "collection #{col.getName}\tin  #{DSpace.create(col).parents.collect { |p| p.getName }}"
  end
end

begin
  parser.parse!
  raise "must give community and file name" if ARGV.length != 2

  com_name = ARGV[0]
  file_name = ARGV[1]

  DSpace.load
  DSpace.login DConstants::LOGIN
  com = DSpace.create(DSpace.fromString(com_name))

  create_collections(com, file_name)

  doit = ask "commit ? (Y/N) "
  if (doit == "Y") then
    DSpace.commit
  end

rescue Exception => e
  puts e.message;
  puts parser.help();
end
