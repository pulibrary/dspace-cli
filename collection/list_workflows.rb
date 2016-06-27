#!/usr/bin/env jruby -I ../dspace-jruby/lib
require 'optparse'
require 'dspace'
require "highline/import"

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} run handle.."
end

def flow_to_hash(flow)
  item = flow.getItem
  metaData = DSpace.create(item).getMetaDataValues
  mdHsh = {}
  metaData.each do |k,v|
    mdHsh[k.fullName] ||= []
    mdHsh[k.fullName] << v
  end
  return {"submit_to" => flow.getCollection.getHandle,
          "flowId" => flow.getID,
          "itemId" => item.getID,
          "state" => flow.getState,
          "owner" =>  DSpace.inspect(flow.getOwner),
          "metaData" => mdHsh}
end


def print_flows(dso)
  DWorkflowItem.findAll(dso).each do |flow|
    hsh = flow_to_hash(flow)
    hsh.each do |k,v|
      if (k == "metaData") then
        puts k
        v.keys.sort.each do |mk|
          mv = v[mk]
          puts "\t#{mk}\t#{mv.collect { |s| s.slice(0,120) }.join('; ')}"
        end
      else
        puts "#{k.inspect}\t#{v.inspect}"
      end
    end
    puts ""
  end
end

begin
  parser.parse!
  raise "must give at least one collection/community parameter" if ARGV.empty?

  DSpace.load

  ARGV.each do |str|
    dso = DSpace.fromString(str)
    puts "# #{dso}"
    print_flows(dso)
    puts ""
  end
rescue Exception => e
  puts e.message;
  puts parser.help();
end