#!/usr/bin/env jruby -I lib
require 'optparse'
require 'dspace'

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [-d]  handle.."

  opts.on("-v", "--[no-]verbose", "Printe detais") do |v|
    options[:details] = v
  end
end

begin
  parser.parse!
  details = options[:details]

  DSpace.load

  ARGV.each do |obj|
    d = DSpace.fromString(obj)
    if (d) then
      puts JSON.pretty_generate(details ? DSpace.create(d).report : DSpace.create(d).dso_report)
    else
      $stderr.puts "ERROR: no such object #{obj}"
    end
  end
rescue Exception => e
  puts e.message;
  puts parser.help();
end



