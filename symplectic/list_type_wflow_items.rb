require 'dspace'
DSpace.load

# Print info for all workflow items

flows = DWorkflowItem.findAll(nil)
flows.each do |f|
    puts [f.getItem.getID, f.getItem.getMetadataByMetadataString('dc.type') ].join "\t"
end
