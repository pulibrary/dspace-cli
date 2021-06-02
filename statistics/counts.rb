#!/usr/bin/env jruby

# Get counts of Items in each Collection. Repeat for all Communities.

require 'dspace'

DSpace.load

puts  ['Community', 'Collection', 'Count', 'Community Name', 'Collection Name'].join("\t")
comms = DCommunity.all
comms.each do |cm|
  colls = cm.get_all_collections
  colls.each do |c|
    count = 0
    items = c.getAllItems
    while items.hasNext
      items.nextID
      count += 1
    end
    puts [cm.getHandle, c.getHandle, count, cm.getName, c.getName].join("\t")
  end
end
