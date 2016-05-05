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
  itemData = DSpace.create(item).getMetaDataValues
  author_title = itemData.select { |f, v| ["dc.contributor.author", "dc.title"].include?(f) }
  itemDataStrs = author_title.collect { |f, v| "#{f}=#{v}" }.sort
  return {"submit_to" => flow.getCollection.getHandle,
          "flowId" => flow.getID,
          "itemId" => item.getID,
          "state" => flow.getState,
          "owner" => DSpace.toString(flow.getOwner),
          "itemData" => itemDataStrs.join(",")}
end


begin
  parser.parse!
  raise "must give at least one collection/community parameter" if ARGV.empty?

  DSpace.load

  ARGV.each do |str|
    dso = DSpace.fromString(str)
    puts "# #{dso}"
    DWorkflowItem.findAll(dso).each do |flow|
      puts flow_to_hash(flow).inspect
    end
    puts ""
  end
rescue Exception => e
  puts e.message;
  puts parser.help();
end