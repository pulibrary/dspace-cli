# for each handle from the comand line print out bitstreams

require 'dspace'
DSpace.load

# print the path to bitstreams in an item
def work_bitstreams(item)
  ditem = DSpace.create(item)
  prefix = ditem.parents.reverse.collect { |p| p.getHandle }.join(' > ')
  DSpace.create(item).bitstreams('ORIGINAL').each do |b|
    puts "#{prefix} > #{item.getHandle}.ORIGINAL.#{b.getName}"
  end
end

# Get all bistreams within JRuby DSO
def loop_bitstreams(dso)
  if dso.getType == DConstants::ITEM
    work_bitstreams(dso)
  else
    if dso.getType == DConstants::COLLECTION
      iter = dso.getItems
      while (itm = iter.next)
        work_bitstreams(itm)
      end
    else
      dcom =  DSpace.create(dso)
      for col in dcom.getCollections do
        loop_bitstreams(col)
      end
    end
  end
end

# for each handle from the comand line print out bitstreams
ARGV.each do |hdl|
  dso = DSpace.fromString(hdl)
  if dso
    # TODO: Remove unnecessary nesting
    loop_bitstreams(dso) if dso
  else
    puts "ERROR: can't find DSpace object #{hdl}"
  end
end
