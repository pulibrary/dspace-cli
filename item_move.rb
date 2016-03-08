#!/usr/bin/env jruby -I lib

# BEWARE:: not fully tested

require 'dspace'
require "highline/import"

DSpace.load

java_import org.dspace.content.Collection
java_import org.dspace.content.DSpaceObject
java_import org.dspace.handle.HandleManager
java_import org.dspace.eperson.EPerson;

DSpace.login(ENV['USER'])

# 88435/dsp019593tx37q

#str= ask "Iten to be moved (handle/or ITEM.<ID>) "
str = '88435/dsp019593tx37q';

item = DSpaceObject.fromString(DSpace.context,  str.strip)
puts  ["Item", "#{item.getName}", "#{item.getHandle}","#{item.toString}"].join("\n\t")
owner = item.getOwningCollection
puts  "owning Collection\n\t#{owner.getHandle}\n\t#{owner.getName}"

parents  = item.getCollections()
parents.each do  |p|
    puts "mapped Collection\n\t#{p.getHandle}\n\t#{p.getName}" unless p == owner
end


#str= ask "new Owning Collection (handle/or COLLECTION.<ID>) "
str = "88435/dsp01pv63g2477";
new_owner = DSpaceObject.fromString(DSpace.context,  str.strip)
puts  "new owning Collection\n\t#{new_owner.getHandle}\n\t#{new_owner.getName}"

str = ask "Please confirm the move (Y/N) "
if (str[0] == 'Y')  then
  puts "moving"
  item.setOwningCollection(new_owner)
  item.update
  DSpace.context.commit
end

# context.complete