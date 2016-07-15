#!/usr/bin/env jruby 
require 'dspace'

DSpace.load

DMetadataSchema.all.each do |s|
  DSpace.create(s).fields.each do |f|
    str = f.getScopeNote || ""
    puts [DSpace.create(f).fullName, str.gsub(/\n/, ' ')].join("\t")
  end
end

