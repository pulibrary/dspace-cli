#!/usr/bin/env jruby
# chngae collection names such that
# 1) those ending in '-'old_year   are changedtoe d int '-'new_year
# 2) those ending in old_year   are changed to end in  old_year-new_year
#
require "highline/import"
require 'cli/dconstants'

year = 2016
schema, element, qualifier = ['pu', 'date', 'classyear']
handle = DConstants::SENIOR_THESIS_HANDLE
require 'dspace'
DSpace.load
DSpace.login ENV['USER']

DSpace.fromString(handle).getCollections.each do |col|
  name = col.getName.strip
  if name.end_with? old_year then
    name = name.chomp("-" + old_year) + ("-" + new_year)
    col.setMetadataSingleValue('dc', 'title', nil, '*', name)
    puts "#{col.getHandle} changing to  #{col.getName}"
    col.update
  else
    puts "#{col.getHandle} keeping      #{col.getName}"
  end
end

DSpace.commit
