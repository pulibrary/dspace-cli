#!/usr/bin/env jruby -I lib

require 'dspace'
DSpace.load

java_import org.dspace.handle.HandleManager

parent = HandleManager.resolveToObject(DSpace.context, '99999/fk4891cv2b');

puts "<collections>"
parent.getCollections.each do |coll|
   puts "    <collection>"
   puts "       <name>#{coll.getName()}</name>"
   puts "       <identifier>#{coll.getHandle()}</identifier>"
   puts "    </collection>"
end
puts "</collections>"

