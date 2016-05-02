#!/usr/bin/env jruby
require 'optparse'
require 'dspace'
require "highline/import"

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} run handle.."
end

class DCollection
  def name_workflow_groups
    colname = @obj.getName.gsub(/\s+/, '_')
    [1, 2, 3].each do |step|
      group = @obj.getWorkflowGroup(step)
      if (group) then
        name = group.getName
        new_name = "#{colname}_STEP_#{step}"
        if (name != new_name) then
          puts "rename group #{name} -> #{new_name}"
          group.setName(new_name)
          group.update
        end
      end
    end
    self
  end

  def name_submitter_group
    colname = @obj.getName.gsub(/\s+/, '_')
    group = @obj.getSubmitters
    name = group.getName
    new_name = "#{colname}_SUBMIT"
    if (name != new_name) then
      puts "rename group #{name} -> #{new_name}"
      group.setName(new_name)
      group.update
    end
    self
  end
end

class DCommunity
  def name_workflow_groups
    @obj.getCollections.each { |col| DSpace.create(col).name_workflow_groups }
    self
  end

  def name_submitter_group
    @obj.getCollections.each { |col| DSpace.create(col).name_submitter_group }
    self
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
      DSpace.create(dso).name_submitter_group.name_workflow_groups
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