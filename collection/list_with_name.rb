#!/usr/bin/env jruby 

require 'dspace'
DSpace.load


def collections_with_name(all,  name) 
    cols = all.select { |col| col.getName.include?(name) } 
    cols.each do |col| 
        objs = DSpace.create(col).parents << col
        puts objs.collect{ |o| [o.getHandle, o.getName ] }.flatten.join("\t")
    end
end 

all = DCollection.all
print "> "
while (name  = ARGF.gets)
    collections_with_name(all, name.strip) 
    print "> "
end
