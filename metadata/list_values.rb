#!/usr/bin/env jruby -I ../dspace-jruby/lib
require 'optparse'
require 'dspace'

require "cli"

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} fully_qualified_metadata.."
end

def doit(metadata_field)
  puts ['field', 'id', 'handle', 'value'].join("\t")
  dsos = DSpace.findByMetadataValue(metadata_field, nil, DConstants::ITEM)
  dsos.each  do  |dso|
    vals = dso.getMetadataByMetadataString(metadata_field).collect { |v| v.value }
    puts [metadata_field, dso.getID, dso.getHandle.nil? ? "null" : dso.getHandle, vals  ].join("\t")
  end
end

begin
  parser.parse!
  raise "must give at least one  fully qualified metadata fieldr" if ARGV.empty?

  DSpace.load

  ARGV.each do |str|
    doit(str);
  end
rescue Exception => e
  puts e.message;
  puts parser.help();
end