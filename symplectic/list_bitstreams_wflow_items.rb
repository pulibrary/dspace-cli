require 'dspace'
DSpace.load

def list_bitstreams_wflow_items
    flows = DWorkflowItem.findAll nil
    flows.each do |f|
        i = f.getItem
        bnames = DSpace.create(i).bitstreams.collect { |b| b.getName }
        puts ([i.toString] + bnames + [i.getMetadataFirstValue('pu', 'author', 'department', nil)]).join "\t"
    end
end


list_bitstreams_wflow_items