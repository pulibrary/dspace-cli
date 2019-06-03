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
    do_one(d)
    n = n + 1
  end
  puts "#items #{n}"
end

def do_one(item)
  created = item.getMetadataByMetadataString("dc.date.created")[0].value
  issued = item.getMetadataByMetadataString("dc.date.issued")
  if issued.length >= 1 then
    issued = issued[0].value
  else
    item.setMetadataSingleValue('dc', "date", "issued", '*', created)
    item.update
    issued = 'NEW:' + item.getMetadataByMetadataString("dc.date.issued")[0].value
  end
  puts [item.getID(), created, issued].join("\t")
end


loop_year(2019)
# DSpace.commit

