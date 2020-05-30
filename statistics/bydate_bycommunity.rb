#!/usr/bin/env jruby

# Print out submission count per community per year and per month. Sort
#   alphabetically by community.

require 'dspace'

DSpace.load

puts ["Field", "Year", "Month", "#Items"].join("\t")
['dc.date.accessioned', 'dc.date.issued'].each do |mdfield|
  submissions = {};
  items = DItem.iter
  while (i = items.next()) do
    date = i.getMetadata(mdfield)
    begin
      year, month = date.split('-')
      community = DSpace.create(i).parents[-1] # top level community
      if (community and community.getHandle) then
        ['total', community.getHandle].each do |bucket|
          submissions[bucket] ||= {}
          submissions[bucket][year] ||= {}
          submissions[bucket][year][month] ||= 0
          submissions[bucket][year][month] += 1
          submissions[bucket][year]['total'] ||= 0
          submissions[bucket][year]['total'] += 1
          submissions[bucket]['total'] ||= {'total' => 0}
          submissions[bucket]['total']['total'] += 1
        end
      else
        $stderr.puts "Item #{i}  in community #{community} without a handle"
      end
    rescue
      $stderr.puts "Item #{i} #{mdfield} value = '#{date}'"
    end
  end
  print "\n"

  puts ["Type", "Year", "Month", "#Items", "Community"].join("\t")
  submissions.keys.sort.each do |bucket|
    submissions[bucket].keys.sort.each do |year|
      submissions[bucket][year].keys.sort.each do |month|
        bname = DSpace.fromString(bucket) ? DSpace.fromString(bucket).getName : ''
        puts [mdfield, year, month, submissions[bucket][year][month], bucket, bname].join("\t")
      end
    end
  end
end