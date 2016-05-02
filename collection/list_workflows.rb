#!/usr/bin/env jruby
require 'optparse'
require 'dspace'
require "highline/import"

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} run handle.."
end

class DCollection
  def list_workflows
    list = []
    self.workflows.each do |flow|
      item = flow.getItem
      itemData = DSpace.create(item).getMetaDataValues
      author_title = itemData.select { |f, v| ["dc.contributor.author", "dc.title"].include?(f) }
      itemDataStrs = author_title.collect { |f, v| "#{f}=#{v}" }.sort
      data = {"submit_to" => @obj.getHandle,
              "flowId" => flow.getID,
              "itemId" => item.getID,
              "state" => flow.getState,
              "owner" => DSpace.toString(flow.getOwner),
              "itemData" => itemDataStrs.join(",")}
      puts data.inspect
      list << data
    end
    list
  end
end

run = ARGV.shift
if (run == "run") then
  begin
    parser.parse!
    raise "must give at least one collection/community parameter" if ARGV.empty?

    DSpace.load

    ARGV.each do |str|
      dso = DSpace.fromString(str)
      dso.list_workflows
    end
  rescue Exception => e
    puts e.message;
    puts parser.help();
  end
end