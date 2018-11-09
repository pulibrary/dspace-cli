require 'dspace'
DSpace.load

def update_pdfs(item)
  for b in DSpace.create(item).bitstreams('ORIGINAL') do
    puts "ITEM: #{item.getHandle()}.ORIGINAL.#{b.getName()}"
  end
end

def loop_bitstreams(dso)
  if (dso.getType == DConstants::ITEM) then
    update_pdfs(dso)
  else
    if (dso.getType == DConstants::COLLECTION) then
      iter =  dso.getItems
      while (itm = iter.next()) do
        update_pdfs(itm)
      end
    else
      dcom =  DSpace.create(dso)
      for col in dcom.getCollections do
        loop_bitstreams(col)
      end
    end
  end
end

ARGV.each do |hdl|
  dso = DSpace.fromString(hdl)
  if (dso) then
    if (dso) then
      loop_bitstreams(dso)
    end
  else
    puts "ERROR: can't find DSpace object #{hdl}"
  end
end
