#!/usr/bin/env jruby 
require "highline/import"
require_relative "modules/collection"

template_hdl = '88435/dsp018c97kq48z';

name = ask "Collection Name "; 
name = name.strip; 

choices = [{ 
name: 'Monographic reports and papers (Access Limited to Princeton)',
hdl:  '88435/dsp01bg257f09p'
}, {
name: 'Monographic reports and papers (Publicly Accessible)',
hdl: '88435/dsp016q182k16g'
}, {
name: 'Serials and series reports (Access Limited to Princeton)',
hdl: '88435/dsp01r781wg06f'
}, {
name: 'Serials and series reports (Publicly Accessible)', 
hdl:  '88435/dsp01kh04dp74g'
}]

puts "Available Parent Collections"
i = 0; choices.each do |c|  
    puts "#{i}: #{c[:name]}";  
    i = i +1
end
ci = ask "Which collection ? "; 
parent = choices[ci.to_i][:hdl]

require 'dspace'
require 'cli/dcollection'

DSpace.load()

puts parent_coll = DSpace.fromString(parent)
puts template_coll  = DSpace.fromString(template_hdl)

puts "Name:\n\t#{name}";  
puts "Parent:\n\t#{parent_coll.getName}"; 
puts "Template Colection:\n\t#{template_coll.getName}\n\tin #{template_coll.getParentObject().getName}"; 
yes = ask "do you want to create ? [Y/N] "
if (yes[0] == 'Y') then
    options =  {
        template_coll: template_coll,
        parent_handle: parent_coll,
        name: name 
    };
    DSpace.login(ENV['USER'])
    newcol = DSpace.create(template_col).copy(name, parent_coll)

    DSpace.commit
    puts "Committed #{new_col.getHandle()}"
    puts "If restricted access: set 'DEFAULT_BITSTREAM_READ' to Princetion_IPs"
    puts "add to dspace/config/input-forms.xml"
    puts '   <name-map collection-handle="' + new_col.getHandle + '" form-name="digpubs_serials"/>'
    puts "commit message"
    puts '   add ' + new_col.getHandle + 'to  form-name="digpubs_serials"'
end







