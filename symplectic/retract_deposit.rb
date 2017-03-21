#!/usr/bin/env jruby
require "highline/import"
require 'dspace'
require 'symplectic/ditem'

DSpace.load
DSpace.context_renew
DSpace.login ENV['USER']


def doit
  while (true) do
    puts "do not include speacial character in the title"
    title = ask("title ")
    return if title.empty?
    do_item title.strip
  end

end

def do_item(title)
  item = get_item(title)
  puts ""

  unless item.nil? then
    if item.isArchived then
      puts "ERROR: can't retract archived item"
    else
      symid = DSpace.create(item).symplecticID
      puts "check in symplectic - should be deposited"
      puts "/repository.html?pub=#{symid}"
      puts "undeposit by removing the license - remember to impersonate the author"

      yes = ask "return when undeposit done > "
      puts "the item below should bbe the same as the one shown above"
      item = get_item(title)
      puts ""
      yes = ask "retract ? (yes/no) "

      if (yes == "yes") then
        item.clearMetadata('pu', 'workflow', 'state', nil)
        item.update
        DSpace.commit
        get_item(title)
      end
    end
  end
  DSpace.context_renew
  DSpace.login ENV['USER']
end

def get_item(title)
  item = DSpace.fromString "TITLE.#{title}%"

  if item.nil? then
    puts ["n/a", "title:", "no match"].join("\t")
  else
    puts [item.getID, "title:", title].join("\t")
    puts [item.getID, "archived:", item.isArchived, item.getName].join("\t")
    puts "pu.workflow.state" + item.getMetadataByMetadataString('pu.workflow.state').collect { |v| v.value }.join(", ")
  end
  item
end