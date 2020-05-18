#!/usr/bin/env jruby 
require "highline/import"
require "cli"
require 'cli/dconstants'

netid = DConstants::LOGIN
name = ask "Collection Name "; 
name = name.strip; 

choices = [ {
name: 'Serials and series reports (Access Limited to Princeton)',
hdl: '88435/dsp01r781wg06f'
}, {
name: 'Serials and series reports (Publicly Accessible)', 
hdl:  '88435/dsp01kh04dp74g'
}]

puts "Available Parent Collections"
i = 0; choices.each do |c|  
    puts "#{i}: #{c[:name]}";  
    i += 1
end
ci = ask "Which collection ? "; 
parent = choices[ci.to_i][:hdl]

require 'dspace'
DSpace.load()
DSpace.login netid

parent_coll = DSpace.fromString(parent)
template_coll  = DSpace.fromString('88435/dsp018c97kq48z')

puts "Name:\n\t#{name}";  
puts "Parent:\n\t#{parent_coll.getName}"; 
puts "Template Colection:\n\t#{template_coll.getName}\n\tin #{template_coll.getParentObject().getName}"; 
yes = ask "do you want to create ? [Y/N] "
if (yes[0] == 'Y') then 
    options =  {
        netid: netid, 
        template_coll: template_coll.getHandle(),
        parent_handle: parent_coll.getHandle(), 
        name: name 
    };
    puts ["PARENT", parent_coll, "\tTEMPLATE",template_coll].join "\t"
    new_col = DSpace.create(template_coll).copy(name, parent_coll)
    DSpace.commit
    puts "Committed #{new_col.getHandle()}"
    puts "If restricted access: set 'DEFAULT_BITSTREAM_READ' to Princetion_IPs"
    puts 'add to input-forms'
    puts '   <name-map collection-handle="' + new_col.getHandle + '" form-name="digpubs_serials"/>'

end







