require 'dspace'
DSpace.load


DSpace.login "monikam"

def move_item(h, new_owner)
  # move item with given handle to the new_owner collection
  item = DSpace.fromString(h)
  puts [item.getHandle, item.getName].join("\t")
  if (item.getCollections.length != 1)
    puts [item.getHandle, "SKIP: item belongs ro more than one collection"].join("\t")
  else
    cur = item.getOwningCollection
    if (cur != new_owner)
      puts [item.getHandle, "MOVE"].join("\t")
      new_owner.addItem(item)
      cur.removeItem(item)
      item.setOwningCollection(new_owner)
      item.update
      cur.update
      new_owner.update
    else
      puts [item.getHandle, "ALREADY at new Loc"].join("\t")
    end
    index(item, true)
  end
  return item
end


def index(dso, force_update)
  puts [dso.getHandle, "indexing"].join("\t")
  java_import org.dspace.discovery.SolrServiceImpl
  idxService = DSpace.getIndexService()
  idxService.indexContent(DSpace.context, dso, force_update)
end

handles = ["88435/dsp01jm214r372",
           "88435/dsp01rb68xf24b",
           "88435/dsp01w95050599",
           "88435/dsp01xp68kg328",
           "88435/dsp01p5547r49g",
           "88435/dsp01pc289m301",
           "88435/dsp01z316q4112",
           "88435/dsp01dv13zw44b",
           "88435/dsp01rj430467r",
           "88435/dsp01gx41mh987",
           "88435/dsp01zc77ss33v",
           "88435/dsp011831cn18c",
           "88435/dsp01hq37vn66m"]

def list(hdls)
  for h in hdls do
    dso = DSpace.fromString(h)
    puts [dso.getHandle, dso.getOwningCollection.getName, dso.getMetadataByMetadataString("dc.contributor.author").collect { |v| v.value }].join("\t")
  end
end

def set_plasma
  plasma = DSpace.fromString('88435/dsp01pg15bd903')
end

set_plasma
dso = DSpace.fromString(h)
#index(dso, true)
