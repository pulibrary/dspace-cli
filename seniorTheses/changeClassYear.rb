#!/usr/bin/env jruby  

# Set metadata on given year

require "highline/import"
require 'cli/dconstants'

year = DConstants::DEFAULT_YEAR
schema, element, qualifier = ['pu', 'date', 'classyear']
handle = DConstants::SENIOR_THESIS_HANDLE
require 'dspace'
DSpace.load

puts "continue with #{year} ?"
ask 'ctr-c to abort'

DSpace.fromString(handle).getCollections.each do |col|
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
