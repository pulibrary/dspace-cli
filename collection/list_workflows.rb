#!/usr/bin/env jruby
require 'optparse'
require 'dspace'

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} handle.."
end

def list_col_workflows(col)
  list = []
  DSpace.create(col).workflows.each do |flow|
    item = flow.getItem
    itemData = DSpace.create(item).getMetaDataValues
    author_title = itemData.select { |f, v| ["dc.contributor.author", "dc.title"].include?(f) }
    itemDataStrs = author_title.collect { |f, v| "#{f}=#{v}" }.sort
    data = {"submit_to" => col.getHandle,
            "flowId" => flow.getID,
            "itemId" => item.getID,
            "state" => flow.getState,
            "owner" => DSpace.to_string(flow.getOwner),
            "itemData" => itemDataStrs.join(",")}
    list << data
  end
  list
end

def list_workflows(collection_name)
  collections = DCollection.findAll(collection_name)
  if collections.empty? then
    $stderr.puts "no such collection #{collection_name}"
  elsif collections.length != 1 then
    $stderr.puts "not a unique collection name #{collection_name}"
  else
    collections.each do |col|
      list_col_workflows(col).each do |entry|
        puts entry.inspect
      end
    end
  end
end

begin
  parser.parse!
  raise "must give at least one collection paramater" if ARGV.empty?

  DSpace.load

  ARGV.each do |obj|
    list_workflows(obj)
  end
rescue Exception => e
  puts e.message;
  puts parser.help();
end
