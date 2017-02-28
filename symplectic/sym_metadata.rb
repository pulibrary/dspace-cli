#!/usr/bin/env jruby
require 'dspace'
require "highline/import"
require 'net/http'
require 'uri'
require 'xmlsimple'
require 'symplectic/ditem.rb'

DSpace.load
#DSpace.login ENV['USER']
puts "\n"
puts  '# prod         http://oaworkflow.princeton.edu:9090/publications-atom/publication/'
puts  '# prod@monika: http://localhost:19091/publications-atom/publication/'
puts  '# dev          http://oaworkflow-dev.princeton.edu:9090/publications-atom/publication/'
puts  '# dev@monika:  http://localhost:19090/publications-atom/publication/'

url = 'http://localhost:19091/publications-atom/publication/'
url = ask 'symplectic publication-url ' unless url

puts "# using #{url}";


puts ['ITEM', 'ItemID', 'SymplecticID', 'Citation'].join "\t"
jsp_url =  DConfig.get('dspace.url') + "/handle/"
DItem.all.each do |i|
  di = DSpace.create(i)
  sid = di.symplecticID

  #  get xml from symplectic
  xml = Net::HTTP.get(URI.parse(url + sid)) if sid
  unless xml then
    puts "# No symplectic equivalent for #{i}"
    next
  end
  fname = "/tmp/#{i}.xml"
  xmlfile= File.open(fname, "w")
  xmlfile.puts xml
  xmlfile.close
  puts ["# process ", fname, i , sid].join("\t")
  # apply style sheet to symplectic xml
  metadata_xml = `cd $DSPACE_HOME/config/crosswalks/symplectic/; xsltproc symplectic_xwalks_dspace_example_default.xsl #{fname} `

  #  et citation from metadata_xml
  fields = XmlSimple.xml_in(metadata_xml)["field"]
  select_citations = fields.select { |f|   f["mdschema"] == "dc" and f["element"] == "identifier" and f["qualifier"] == "citation" }
  citation = select_citations[0]["content"]

  # print table entry
  puts [jsp_url + i.getHandle, i.getID, sid, citation].join "\t"
end



if false then
stylesheet = File.readlines("stylesheet.xsl").to_s
xml_doc = File.readlines("document.xml").to_s
arguments = { 'image_dir' => '/....' }

sheet = XSLT::Stylesheet.new( stylesheet, arguments )

# output to StdOut
sheet.apply( xml_doc )

# output to 'str'
str = ""
sheet.output = [ str ]
sheet.apply( xml_doc )end