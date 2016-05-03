
class DCommunity
  def find_collection_by_name(name)
    @obj.getCollections.select { |c| c.getName == name  }[0]
  end

  def find_or_create_collection_by_name(name)
    col = find_collection_by_name(name)
    if col.nil? then
      col = @obj.createCollection()
      col.setMetadataSingleValue("dc", "title", nil, nil, name)
      col.update
    end
    col
  end

  def name_workflow_groups
    @obj.getCollections.each { |col| DSpace.create(col).name_workflow_groups }
    self
  end

  def name_submitter_group
    @obj.getCollections.each { |col| DSpace.create(col).name_submitter_group }
    self
  end

  def find_or_create_workflow_group(step)
    @obj.getCollections.collect { |col| DSpace.create(col).find_or_create_workflow_group(step) }
  end
end