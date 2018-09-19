#!/usr/bin/env jruby -I ../dspace-jruby/lib
require 'optparse'
require 'dspace'

require "cli"

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} handle.."
end

def bitstream_to_hash(bit)
  return {"name" => bit.getName,
          "format" => bit.getFormat.getDescription,
          "checksum" => bit.getChecksum,
          "size" => bit.getSize,
          "parents" => DSpace.create(bit).parents.collect{ |p| p.getHandle }}
end

def doit(str)
  dso = DSpace.fromString(str)
  puts "# #{dso}"
  DSpace.create(dso).bitstreams.each do |bit|
    puts bitstream_to_hash(bit)
  end
  puts ""
end

begin
  parser.parse!
  raise "must give at least one collection/community/item parameter" if ARGV.empty?

  DSpace.load

  ARGV.each do |str|
    doit(str)
  end
rescue Exception => e
  puts e.message;
  puts parser.help();
end