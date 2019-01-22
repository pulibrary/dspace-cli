require 'dspace'
require 'symplectic/ditem'

DSpace.load

def list_bitstreams_wflow_items
    flows = DWorkflowItem.findAll nil
    flows.each do |f|
        i = f.getItem
        bnames = DSpace.create(i).bitstreams.collect { |b| b.getName }
        puts ([i.toString] + bnames + [i.getMetadataFirstValue('pu', 'author', 'department', nil)]).join "\t"
    end
end


def id_info(i)
    s = "ITEM.#{i.getID}->Sy-ID.#{DSpace.create(i).symplecticID }"
end

def list_author_uid_wflow_items
    flows = DWorkflowItem.findAll nil
    flow_ids = flows.collect{|f| f.getItem.getID}
    uid_info = {}

    flows.each do |f|
        i = f.getItem
        uids = i.getMetadata('pu', 'author', 'uniqueid', '*').collect{|mv| mv.value}
        for u in uids do
            if uid_info.key?(u) then
                uinfo = uid_info[u]
            else
                uid_items =   DSpace.findByMetadataValue('pu.author.uniqueid', u, DConstants::ITEM)
                handles =  (uid_items.collect{ |i| i.getHandle()}.uniq - [nil])
                w_states =  uid_items.collect{ |i| i.getMetadataFirstValue('pu', 'workflow', 'state', nil) }.uniq
                uinfo = { 'total' => uid_items.length, 'items' => uid_items, 'handles' => handles, 'states' => w_states}
                uinfo['published'] = uinfo['handles'].length
                uinfo['workflow'] = uinfo['total'] - uinfo['published']
                uid_info[u] = uinfo
            end
            #puts [i.toString, uids.join('|'), uinfo['workflow'], uinfo['published'], uinfo['total'], authors.join('|')].join("\t")
        end
    end

    puts ['UID', 'workflow', 'published', 'total', 'states', 'ids', 'handles'].join("\t")
    for u in uid_info.keys do
        uinfo = get_uinfo(u, flow_ids)

        f_ids = []
        hidden_ids = []
        for i in uinfo['items'] do
            if (i.getHandle == nil) then
                if (flow_ids.include? i.getID) then
                    f_ids << i.getID
                else
                    hidden_ids << i.getID
                end
            end
        end
        uinfo['ids'] = f_ids
        uinfo['hidden_ids'] = flow_ids
        puts [u, uinfo['workflow'], uinfo['published'], uinfo['total'], uinfo['states'], uinfo['ids'].join(","), uinfo['hidden_ids'].join(","), uinfo['handles'].join(",")].join("\t")
    end
end


def list_author_uid_wflow_items
    flows = DWorkflowItem.findAll nil
    flow_ids = flows.collect{|f| f.getItem.getID}
    uids = []

    flows.each do |f|
        i = f.getItem
        uids = i.getMetadata('pu', 'author', 'uniqueid', '*').collect{|mv| mv.value}
        for u in uids do
            uids << u
        end
    end

    #puts ['UID', 'workflow', 'published', 'total', 'states', 'ids', 'handles'].join("\t")
    for u in uids.uniq do
        uinfo = get_uinfo(u, flow_ids)
        puts uinfo.collect{ |k,v|  "#{k}={v}"}.join("\t")
    end
end



def get_uinfo(u, flow_ids)
    uinfo = { 'UID' => u, 'handles' => [], 'ids' => [], 'hidden' => ''}
    uid_items =   DSpace.findByMetadataValue('pu.author.uniqueid', u, DConstants::ITEM)

    for i in uid_items do
        if (i.getHandle) then
            uinfo['handles'] << i.getHandle()
        else
            if (flow_ids.include? i.getID) then
                uinfo['ids'] << i.getID
            else
                uinfo['hidden'] << i.getID
            end
        end
    end
    uinfo['states'] = uid_items.collect{ |i| i.getMetadataFirstValue('pu', 'workflow', 'state', nil) }.uniq

    uinfo = uinfo.merge ({ 'total' => uid_items.length, 'nids' => uinfo['ids'].length, 'nhidden' => uinfo['hidden'].length, 'nhandle' => uinfo['handles'].length})
    return uinfo

end


#list_bitstreams_wflow_items

list_author_uid_wflow_items