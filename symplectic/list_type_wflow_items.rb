require 'dspace'
DSpace.load

flows = DWorkflowItem.findAll(nil)
flows.each do |f|
    puts [f.getItem.getID, f.getItem.getMetadataByMetadataString('dc.type') ].join "\t"
end
