#!/usr/bin/env jruby

# Given a filename with a list of collection names, create new collections into
#   the given community handle

require 'optparse'
require 'highline/import'
require 'dspace'
require 'cli/dcommunity'
require 'cli/dconstants'

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} community file_with_collection_names"
end

# Create a collection into community "com" for each line in file
def create_collections(com, file_name)
  name_file = File.new(file_name, 'r')
  dcom = DSpace.create(com)
  name_file.readlines.each do |name|
    col = dcom.find_or_create_collection_by_name(name.strip)
    puts "collection #{col.getName}\tin  #{DSpace.create(col).parents.collect { |p| p.getName }}"
  end
end

begin
  parser.parse!
  raise 'must give community and file name' if ARGV.length != 2

  com_name = ARGV[0]
  file_name = ARGV[1]

  DSpace.load
  DSpace.login DConstants::LOGIN
  com = DSpace.create(DSpace.fromString(com_name))

  create_collections(com, file_name)

  doit = ask 'commit ? (Y/N) '
  DSpace.commit if doit == 'Y'
rescue Exception => e
  puts e.message
  puts parser.help
end
