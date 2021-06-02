#!/usr/bin/env jruby -I ../dspace-jruby/lib

# Print workflows from given DSO handle

require 'optparse'
require 'dspace'
require 'highline/import'
require 'cli/dmetadata'

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} run handle.."
end

# TODO: Add .to_h method to our DWorkFlowItem.rb
def flow_to_hash(flow)
  java_import org.dspace.workflow.WorkflowManager
  item = flow.getItem
  metaData = DSpace.create(item).getMetaDataValues
  mdHsh = DMetadataField.arrayToHash metaData
  { 'submit_to' => flow.getCollection.getHandle,
    'flowId' => flow.getID,
    'itemId' => item.getID,
    'state' => [flow.getState, WorkflowManager.getWorkflowText(flow.getState)],
    'owner' => DSpace.inspect(flow.getOwner),
    'metaData' => mdHsh }
end

def print_metadata(hsh)
  hsh.keys.sort.each do |mk|
    mv = hsh[mk]
    puts "\t#{mk}\t#{mv.collect { |s| s.slice(0, 60) }.join('; ')}"
  end
end

def print_flows(dso)
  DWorkflowItem.findAll(dso).each do |flow|
    hsh = flow_to_hash(flow)
    hsh.each do |k, v|
      if k == 'metaData'
        puts k
        print_metadata(v)
      else
        puts "#{k.inspect}\t#{v.inspect}"
      end
    end
    puts ''
  end
end

begin
  parser.parse!
  raise 'must give at least one collection/community parameter' if ARGV.empty?

  DSpace.load

  ARGV.each do |str|
    dso = DSpace.fromString(str)
    puts "# #{dso}"
    print_flows(dso)
    puts ''
  end
rescue Exception => e
  puts e.message
  puts parser.help
end
