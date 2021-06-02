#!/usr/bin/env jruby -I ../dspace-jruby/lib

# List specially marked items with provenance formats listed below.

require 'time'
require 'dspace'

require 'cli'

DSpace.load

# relying on provenance formats as shown here
p = 'Made available in DSpace on 2019-01-09T22:43:23Z (GMT). No. of bitstreams: 2
 Behavioral_Ecological_Implications_Bunched_2018.pdf: 987134 bytes, checksum: 7e4afd1f8a4248b1bf63b54c58281816 (MD5)
 princeton-oa-license.txt: 268 bytes, checksum: bf6a7d1b45566d473546ae941b49741b (MD5)
 Previous issue date: 2018-01-01'

p = 'Approved for entry into archive by Melissa Lohrey (mlohrey@princeton.edu) on 2019-01-09T22:42:32Z (GMT) No. of bitstreams: 2
 Behavioral_Ecological_Implications_Bunched_2018.pdf: 987134 bytes, checksum: 7e4afd1f8a4248b1bf63b54c58281816 (MD5)
 princeton-oa-license.txt: 268 bytes, checksum: bf6a7d1b45566d473546ae941b49741b (MD5)
'

def list_items
  puts %w[handle approve_date archive_date].join("\t")
  list_archived_items
  list_workflow_items
end

def list_workflow_items
  for wi in DWorkflowItem.findAll(nil) do
    handle, approve_date, archive_date = do_item(wi.getItem)
    puts [handle, approve_date, archive_date].join("\t") if approve_date != ''
  end
end

def list_archived_items
  iter = DItem.iter
  while (i = iter.next)
    handle, approve_date, archive_date = do_item(i)
    puts [handle, approve_date, archive_date].join("\t")
  end
end

def do_item(i)
  handle = i.getHandle || "ITEM.#{i.getID}"
  provenances = i.getMetadataByMetadataString('dc.description.provenance').collect { |v| v.value}
  approve_date = ''
  archive_date = ''
  for p in provenances do
    if p.start_with?('Approved for entry into archive')
      approve_date =  date_string(p.split(')')[1].split(' ')[1])
    elsif p.start_with?('Made available in')
      archive_date =  date_string(p.split[5])
    end
  end
  [handle, approve_date, archive_date]
end

def date_string(t)
  Time.parse(t).to_date.to_s
end

begin
  dso = DSpace.fromString('88435/pr1jm4q')
  # puts do_item(dso)
  list_items
rescue Exception => e
  puts e.message
  puts parser.help
end
