# UNFINISHED
# 
# If worthwhile, place this file under the "list" dir, and allow cli input for
# community, along the lines of "list_items_in_collection.rb". Otherwise, this
# file isn't very useful unless one manually plugs in a community.

require 'dspace'

DSpace.load

com = DSpace.fromString('88435/dsp01td96k251d')

def doit(com)
  colls = DItem.inside(com)
  for c in colls  do
      dso = DSpace.create(c)
      puts [c.getHandle, c.getParentObject.getHandle,   dso.bitstreams.length, c.getMetadataFirstValue('dc', 'contributor', 'author', nil), c.getParentObject.getName].join("\t")
  end
end

doit(com)