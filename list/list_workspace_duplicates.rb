#!/usr/bin/env jruby -I ../dspace-jruby/lib
require 'optparse'
require 'dspace'
require "highline/import"
require 'cli/dmetadata'
require "highline/import"

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} netid.."
end

def loop_witems(netid)
  DWorkspaceItem.findByNetId(netid).each do |witem|
    prefix = "WSPACE-#{witem.getID()}"
    hsh = _to_hash(witem)
    hsh.each do |k, v|
      if (k == "metaData") then
        #puts "#{prefix}\titem-metadata"
        #print_metadata(v,prefix + "\t")
      else
        puts "#{prefix}\t#{k.inspect}\t#{v.inspect}"
      end
    end
    if (false and hsh['should-delete']) then
      # unfortunately there is something else that refers to items
      do_del = ask("delete ? [Y/N] ")
      if (do_del.upcase == 'Y') then

        witem.deleteWrapper
        witem.getItem.delete
        DSpace.commit
      end
    end
    puts ""
  end
end

def _to_hash(wspace)
  java_import org.dspace.workflow.WorkflowManager;
  item = wspace.getItem
  metaData = DSpace.create(item).getMetaDataValues
  mdHsh = DMetadataField.arrayToHash metaData

  # archived items with same title
  duplicates = DSpace.findByMetadataValue('dc.title', item.getName(), DConstants::ITEM)
  duplicates = duplicates.select{|i| i.archived?}

  hsh = { #"wspace_id" => wspace.getID,
          "title" => mdHsh['dc.title'][0],
          "author" => mdHsh['dc.contributor.author'],
          "submit_to_name" => wspace.getCollection.getName,
          "submit_to_handle" => wspace.getCollection.getHandle,
          "duplicates" => duplicates.collect{ |d| "http://dataspace.princeton.edu/jspui/handle/#{d.getHandle()}"},
          "itemId" => item.getID
         #"metaData" => mdHsh
  }

  if (false) then
  hsh = hsh.merge({"wflows-for-itemid" => DWorkflowItem.findAll(item),
             "no-wflows-for-itemid" => DWorkflowItem.findAll(item).empty?})

  hsh = hsh.merge({"archived_with_title" => duplicates.collect{ |d| "http://dataspace.princeton.edu/jspui/handle/#{d.getHandle()}"} ,
             "has-duplicates" => (not duplicates.empty?())})

   hsh["should-delete"] = (hsh["no-wflows-for-itemid"] and hsh["has-duplicates"])
  end
   return hsh
end

def print_metadata(hsh, prefix="")
  hsh.keys.sort.each do |mk|
    mv = hsh[mk]
    puts "#{prefix}\t#{vi append_library}\t#{mv.collect {|s| _format_value(s)}.join(";\n#{prefix}\t\t ")}"
  end
end

def _format_value(s)
  if (s.is_a? String) then
    if s then
      return s.gsub(/[\r\n]+/m, " | ").slice(0, 120)
    else
      return ''
    end
  end
  return s
end


begin
  parser.parse!
  raise "must give at least one netid for the workspaceitem  submitter" if ARGV.empty?

  DSpace.load
  DSpace.login(ENV['USER'])

  ARGV.each do |str|
    puts "# #{str}"
    loop_witems(str)
    puts ""
  end
rescue Exception => e
  puts e.message;
  puts e.backtrace

  puts parser.help();
end