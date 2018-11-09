#!/usr/bin/env jruby -I ../dspace-jruby/lib
require 'optparse'
require 'dspace'

require "cli"

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} fully_qualified_metadata  [value]"
end

def list_selected_by_metadata(metadata_field, value_like)
  puts ['field', 'id', 'handle', 'value'].join("\t")
  dsos = DSpace.findByMetadataValue(metadata_field, value_like, DConstants::ITEM)
  dsos.each  do  |dso|
    vals = dso.getMetadataByMetadataString(metadata_field).collect { |v| v.value }
    parents = DSpace.create(dso). parents().reverse
    puts ([metadata_field, vals, dso.getID, dso.getHandle.nil? ? "null" : dso.getHandle ] + parents.collect{|p| "'#{p.getName()}'"}).join("\t")
  end
end

begin
  parser.parse!
  raise "must give fully qualified metadata field" if ARGV.empty?
  field = ARGV[0]
  value_like  = ARGV[1]
  puts field , value_like

  DSpace.load
  list_selected_by_metadata(field, value_like)

rescue Exception => e
  puts e.message;
  puts parser.help();
end