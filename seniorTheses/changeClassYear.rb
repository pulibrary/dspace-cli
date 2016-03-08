#!/usr/bin/env jruby  -I lib -I utils
require "highline/import"

year = 2016
schema, element, qualifier = ['pu', 'date', 'classyear']
handle = '88435/dsp019c67wm88m'


require 'dspace'
DSpace.load

puts "continue with #{year} ?"
ask 'ctr-c to abort'

com = DSO.fromString(handle)
colls = com.getCollections


colls.each do |col|
  template = col.get_template_item
  if (template) then
    puts "#{col.getHandle} template item #{template} set #{year}"
    template.setMetadataSingleValue(schema, element, qualifier, nil, year.to_s)
    template.update_metadata
    template.update
  else
    puts "#{col.getHandle} has no template item: #{col.getName}"
  end

end

DSpace.commit

