#!/usr/bin/env jruby

# Following prompts, create a new collection.
# TODO: Compare to seniorTheses/createCollection.rb

require 'highline/import'
require 'cli'
require 'cli/dconstants'

netid = DConstants::LOGIN
name = ask 'Collection Name '
name = name.strip

choices = [{
  name: 'Princeton University Undergraduate Senior Theses',
  hdl: DConstants::SENIOR_THESIS_HANDLE
}]

puts 'Parent Collections'
i = 0; choices.each do |c|
  puts "#{i}: #{c[:name]}"
  i += 1
end
ci = ask 'Which collection ? '
parent = choices[ci.to_i][:hdl]

require 'dspace'
DSpace.load
DSpace.login netid

parent_coll = DSpace.fromString(parent)
template_coll = DSpace.fromString('88435/dsp01c247ds15b')

puts "Name:\n\t#{name}"
puts "Parent:\n\t#{parent_coll.getName}"
puts "Template Colection:\n\t#{template_coll.getName}\n\tin #{template_coll.getParentObject.getName}"
yes = ask 'do you want to create ? [Y/N] '
if yes[0] == 'Y'
  options =  {
    netid: netid,
    template_coll: template_coll.getHandle,
    parent_handle: parent_coll.getHandle,
    name: name
  }
  puts ['PARENT', parent_coll, "\tTEMPLATE", template_coll].join "\t"
  new_col = DSpace.create(template_coll).copy(name, parent_coll)
  DSpace.commit
  puts "Committed #{new_col.getHandle}"
  puts "If restricted access: set 'DEFAULT_BITSTREAM_READ' to Princetion_IPs"
  puts 'add to dspace/config/input-forms.xml'
  puts '   <name-map collection-handle="' + new_col.getHandle + '" form-name="digpubs_serials"/>'
  puts 'commit message'
  puts '   add ' + new_col.getHandle + ' to  form-name="digpubs_serials"'

end
