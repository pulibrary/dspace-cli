#!/usr/bin/env jruby

# Go through all items and count the submissions per month and year.

require 'dspace'

DSpace.load

puts ["Field", "Year", "Month", "#Items"].join("\t")
['dc.date.accessioned', 'dc.date.issued'].each do |mdfield|
  items= DItem.iter
  submissions = {};
  while (i = items.next()) do
    date = i.getMetadata(mdfield)
    begin
      year, month = date.split('-')
      submissions[year] ||= {'total' => 0}
      submissions[year][month] ||= 0
      submissions[year][month] += 1
      submissions[year]['total'] += 1
    rescue
      puts "Item #{i} #{mdfield} value = '#{date}'"
    end
  end
  submissions.keys.sort.each do |y|
    submissions[y].keys.sort.each do |m|
      puts [mdfield, y, m, submissions[y][m]].join("\t")
    end
  end
end