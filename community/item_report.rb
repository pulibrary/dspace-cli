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