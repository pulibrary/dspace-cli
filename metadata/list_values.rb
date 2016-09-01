#!/usr/bin/env jruby -I ../dspace-jruby/lib
require 'optparse'
require 'dspace'

require "cli"

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} fully_qualified_metadata.."
end

def doit(str)
  puts str
  dsos = DSpace.findByMetadataValue(str, nil, DConstants::ITEM)
  vals = []
  dsos.each  {  |dso|  vals += dso.getMetadataByMetadataString(str).collect { |v| v.value }  }
  vals.uniqu
end

begin
  parser.parse!
  raise "must give at least one  fully qualified metadata fieldr" if ARGV.empty?

  DSpace.load

  ARGV.each do |str|
    doit(str)
  end
rescue Exception => e
  puts e.message;
  puts parser.help();
end