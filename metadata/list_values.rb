#!/usr/bin/env jruby -I ../dspace-jruby/lib
require 'optparse'
require 'dspace'

require "cli"

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} fully_qualified_metadata.."
end

def doit(str)
  dsos = DSpace.findByMetadataValue(str, nil, DConstants::ITEM)
  vals = []
  dsos.each  {  |dso|  vals += dso.getMetadataByMetadataString(str).collect { |v| v.value }  }
  vals.uniq
end

begin
  parser.parse!
  raise "must give at least one  fully qualified metadata fieldr" if ARGV.empty?

  DSpace.load

  ARGV.each do |str|
    puts [str, doit(str)].join "\t";
  end
rescue Exception => e
  puts e.message;
  puts parser.help();
end