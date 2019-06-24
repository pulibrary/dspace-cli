require 'irb/completion'

require 'dspace'
DSpace.load

# the first uploaded batch in 2019  did not have dc.date.issued metadata value
# the value was instead stored in dc.date.created
# this code copies - if there is no dc.date/issued value in place
# you must by uncommented DSpace.commit
#
year = 2019

def loop_year(year)
  dsos = DSpace.findByMetadataValue('pu.date.classyear', year, DConstants::ITEM)
  n = 0
  dsos.each do |d|
    n = n  + do_one(d)
  end
  puts "#items #{n}"
end

def do_one(item)
  if not item.isArchived  then
    issued = item.getMetadataByMetadataString("dc.date.issued")
    if issued.length >= 1 then
      puts [item.getID(), issued[0]].join("\t")
      puts "should delete"
      item.clearMetadata('dc', 'date', 'issued', '*')
      item.update
    else
      puts [item.getID(), 'no issued'].join("\t")
    end
    return 1
  end
  return 0
end

loop_year(2019)
# DSpace.commit

