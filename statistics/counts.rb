#!/usr/bin/env jruby
require 'dspace'

DSpace.load

comms = DCommunity.all;
comms.each do |cm|
   colls = cm.get_all_collections
   colls.each do |c|
     count = 0;
     items = c.getAllItems;
     while (items.hasNext) do
       items.nextID
       count = count + 1;
     end
     puts  "#{c.getHandle}\t#{c.getParentObject().getHandle()}\t#{count}\t#{c.getName()}"
   end
end
