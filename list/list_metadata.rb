#!/usr/bin/env jruby -I ../dspace-jruby/lib

# List sorted metadata of DSO from handle provided by command line

require 'optparse'
require 'dspace'

require 'cli'

DSpace.load

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} hendale/ITEM.<ID>/TITLE.<STR>.."
end

# Print sorted hash of DSO
def list_metadata(dso_or_str)
  dso = if dso_or_str.is_a? String
          DSpace.fromString(dso_or_str)
        else
          dso_or_str
        end

  puts "# #{dso}"
  if dso
    # LATER: I think we have a to hash function specifically for this.
    hsh = {}
    DSpace.create(dso).getMetaDataValues.each do |m|
      hsh[m[0].inspect] = m[1]
    end
    hsh.keys.sort.each do |k|
      puts "#{k}\t=#{hsh[k]}"
    end
    puts ''
  end
end

begin
  parser.parse!
  raise 'must give at least one collection/community/item parameter' if ARGV.empty?

  DSpace.load

  ARGV.each do |str|
    list_metadata(str)
  end
rescue Exception => e
  puts e.message
  puts parser.help
end
