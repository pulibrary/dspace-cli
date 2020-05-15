#!/usr/bin/env jruby  -I ../dspace-jruby/lib
require "highline/import"
require 'dspace'
require 'symplectic/ditem'
require 'cli/dconstants'

DSpace.load
DSpace.context_renew
DSpace.login DConstants::LOGIN

$dspace_url = 'http://oar-dev.princeton.edu'
$symplectic_url = 'https://oaworkflow-dev.princeton.edu'

$dspace_url = 'http://oar.princeton.edu'
$symplectic_url = 'https://oaworkflow.princeton.edu'

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
      puts "check in symplectic - should be deposited"
      puts get_symplectic_url(DSpace.create(item))
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
        item = get_item(title)
        print_msg(DSpace.create(item))
      end
    end
  end
  DSpace.context_renew
  DSpace.login ENV['USER']
end

def get_symplectic_url(ditem)
  symid = ditem.symplecticID
  return "#{$symplectic_url}/viewobject.html?cid=1&id=#{symid}"
end

def get_item(title)
  item = DSpace.fromString "TITLE.#{title}%"

  if item.nil? then
    puts ["n/a", "title:", "no match"].join("\t")
  else
    puts [item.getID, "title:", title].join("\t")
    puts [item.getID, "archived:", item.isArchived, item.getName].join("\t")
    puts [item.getID, "pu.workflow.state",  item.getMetadataByMetadataString('pu.workflow.state').collect { |v| v.value }.join(", ")].join("\t")
  end
  item
end

def print_msg(di)
  print "the article '#{di.dso.getName}' is now un-deposited
it will take up to an hour for the report on reviewed articles to update
look for ITEM.#{di.dso.getID}
+ see #{$dspace_url}/www/reports/Reviewed.list

please adjust the exception status accordingly in symplectic
+ the link is #{get_symplectic_url(di)}

"
end

# uncomment for testing
doit
