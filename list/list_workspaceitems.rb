#!/usr/bin/env jruby -I ../dspace-jruby/lib

# Print WorkspaceItems

require 'optparse'
require 'dspace'
require 'highline/import'
require 'cli/dmetadata'

parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} netid.."
end

def print_witems(netid)
  DWorkspaceItem.findByNetId(netid).each do |witem|
    prefix = "WSPACE-#{witem.getID}"
    hsh = _to_hash(witem)
    hsh.each do |k, v|
      if k == 'metaData'
        puts "#{prefix}\titem-metadata"
        print_metadata(v, prefix + "\t")
      else
        puts "#{prefix}\t#{k.inspect}\t#{v.inspect}"
      end
    end
    puts ''
  end
end

# TODO: add to_h to WorkSpaceItem Class
def _to_hash(wspace)
  java_import org.dspace.workflow.WorkflowManager
  item = wspace.getItem
  metaData = DSpace.create(item).getMetaDataValues
  mdHsh = DMetadataField.arrayToHash metaData
  { 'wspace_id' => wspace.getID,
    'submit_to' => wspace.getCollection.getHandle,
    'itemId' => item.getID,
    'metaData' => mdHsh }
end

def print_metadata(hsh, prefix = '')
  hsh.keys.sort.each do |mk|
    mv = hsh[mk]
    puts "#{prefix}\t#{mk}\t#{mv.collect { |s| _format_value(s)}.join(";\n#{prefix}\t\t ")}"
  end
end

def _format_value(s)
  if s.is_a? String
    if s
      return s.gsub(/[\r\n]+/m, ' | ').slice(0, 120)
    else
      return ''
    end
  end
  s
end

def print_item(item, pref = '')
  puts "#{pref}ITEM-#{item.getID} #{item.getMetadataFirstValue('dc', 'title', nil, '*')}\t#{item.getHandle}"

  metaData = DSpace.create(item).getMetaDataValues
  mdHsh = DMetadataField.arrayToHash metaData
  print_metadata(mdHsh, "\t#{pref}")
end

begin
  parser.parse!
  raise 'must give at least one netid for the workspaceitem  submitter' if ARGV.empty?

  DSpace.load

  ARGV.each do |str|
    puts "# #{str}"
    print_witems(str)
    puts ''
  end
rescue Exception => e
  puts e.message
  puts parser.help
end
