#!/usr/bin/env jruby
require 'dspace'

DSpace.load

items = DItem.iter

submissions = {};
while (i = items.next()) do
  # proper handle - so lets count this one
  date = i.getMetadata('dc.date.accessioned')
  begin
    year, month = date.split('-')
    community = DSpace.create(i).parents[-1] # top level community
    if (community and community.getHandle) then
      ['total', community.getHandle].each do |bucket|
        submissions[bucket] ||= {}
        submissions[bucket][year] ||= {}
        submissions[bucket][year][month] ||= 0
        submissions[bucket][year][month] += 1
      end
    else
      $stderr.puts "Item #{i}  in community #{community} without a handle"
    end
  rescue
    $stderr.puts "Item #{i} 'dc.date.accessioned' value = '#{date}'"
  end
end

puts ["Year", "Month", "#Items", "Community"].join("\t")
submissions.keys.sort.each do |bucket|
  submissions[bucket].keys.sort.each do |year|
    submissions[bucket][year].keys.sort.each do |month|
      bname = DSpace.fromString(bucket) ? DSpace.fromString(bucket).getName : ''
      puts [year, month, submissions[bucket][year][month], bucket, bname].join("\t")
    end
  end
end
