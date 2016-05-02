#!/usr/bin/env jruby
require 'optparse'
require 'dspace'
require "highline/import"

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} run community file_with_collection_names"
end

class DCommunity
  def find_collection_by_name(name)
    @obj.getCollections.select { |c| c.getName == name  }[0]
  end

  def find_or_create_collection_by_name(name)
   col = find_collection_by_name(name)
   if col.nil? then
      col = @obj.createCollection()
      col.setMetadataSingleValue("dc", "title", nil, nil, name)
      col.update
   end
    col
  end
end

if false then
  com_name = "COMMUNITY.21";  com = DSpace.create(DSpace.fromString(com_name))

end
run = ARGV.shift
if (run == "run") then
  begin
    parser.parse!
    raise "must give community and file name" if ARGV.length != 2

    com_name = ARGV[0]
    name_file = File.new(ARGV[1], "r")

    DSpace.load
    DSpace.login ENV['USER']
    com = DSpace.create(DSpace.fromString(com_name))
    name_file.readlines.each do |name|
      col = com.find_or_create_collection_by_name(name.strip)
      puts "collection #{col.getName}\tin  #{DSpace.create(col).parents.collect{|p| p.getName}}"
    end

    doit = ask "commit ? (Y/N) "
    if (doit == "Y") then
      DSpace.commit
    end

  rescue Exception => e
    puts e.message;
    puts parser.help();
  end
end