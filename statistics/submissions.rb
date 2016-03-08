#!/usr/bin/env jruby
require 'dspace'

DSpace.load

items = DItem.iter

submissions = {};
while (i = items.next() ) do
   date =  i.getMetadata('dc.date.accessioned')
  begin
    year, month =  date.split('-')
   submissions[year] ||= {}
   submissions[year][month] ||= 0
   submissions[year][month]  += 1
  rescue
    puts "Item #{i} 'dc.date.accessioned' value = '#{date}'"
  end
end

puts ["Year", "Month", "#Items"].join("\t")
submissions.keys.sort.each do |y|
  submissions[y].keys.sort.each do |m|
    puts [y,m,submissions[y][m]].join("\t")
  end
end
