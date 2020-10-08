#!/usr/bin/env jruby

# For each handle provided by the command line, query solr for "statistics/select",
#   printing out info like country, city, ip address, and dns.
# QUESTION: What might "statistics_type" mean?

require 'rsolr'
require 'dspace'

DSpace.load

query_defaults = {
  q: 'type:0', # 0 -> bitstream, 2 items, 3 collections, 4 communities
  rows: 100_000,         # return  up to these many rows
  sort: 'time desc'      # sort by time in reverse
}

solr_url = 'http://localhost:18083/solr'
puts "using solr: #{solr_url}"
solr = RSolr.connect url: solr_url

owningFields = { 'org.dspace.content.Item' => 'owningItem',
                 'org.dspace.content.Collection' => 'owningColl',
                 'org.dspace.content.Community' => 'owningComm' }

puts "# statistics events where #{query_defaults.inspect}"

ARGV.each do |hdl|
  obj = DSpace.fromHandle(hdl)
  if obj
    puts "# events relating to #{obj}"
    owner = owningFields[obj.getClass.getName]
    matches = solr.get 'statistics/select',
                       params: query_defaults.merge({ fq: ["#{owner}:#{obj.getID}"] })
    puts "# #{matches['response']['numFound']} event matches for #{matches['responseHeader'].inspect}"

    headers = %w[handle type id statistics_type bundleName owningItem owningColl owningComm time continent countryCode city ip dns]
    puts headers.join("\t")
    matches['response']['docs'].each do |doc|
      row = [obj.getHandle]
      headers[1..-1].each do |prop|
        row << doc[prop]
      end
      puts row.join(',')
    end
  else
    puts "# no such object #{hdl}"
  end
end
