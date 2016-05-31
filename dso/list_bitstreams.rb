#!/usr/bin/env jruby -I ../dspace-jruby/lib
require 'optparse'
require 'dspace'

require "cli/dcommunity"
require "cli/dcollection"
require "cli/ditem"

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


begin
  parser.parse!
  raise "must give at least one collection/community/item parameter" if ARGV.empty?

  DSpace.load

  ARGV.each do |str|
    dso = DSpace.fromString(str)
    puts "# #{dso}"
    DSpace.create(dso).getBitstreams.each do |bit|
      puts bitstream_to_hash(bit)
    end
    puts ""
  end
rescue Exception => e
  puts e.message;
  puts parser.help();
end