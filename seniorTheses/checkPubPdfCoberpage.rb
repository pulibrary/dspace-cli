#!/usr/bin/env jruby  -I lib -I utils
require 'dspace'
require 'cli/dconstants'

DSpace.load

year = DConstants::DEFAULT_YEAR
items = DSpace.findByMetadataValue("pu.date.classyear", year, nil)

hitems = items.select { |i| i.is_archived }

def listCoverPageStatus(hitems)
  hitems.each do |i|
    vals = i.getMetadata("pu", "pdf", "coverpage", nil);
    if (vals.length == 0) then
      puts "#{i.getHandle()} missing  pu.pdf.coverpage"
    else
      vals = i.getMetadata("pu", "pdf", "coverpage", nil).collect { |v| v.value };;
      vals = vals.join(', ');
      puts "#{i.getHandle()} has      pu.pdf.coverpage = #{vals}"
    end
  end
end

listCoverPageStatus(hitems)