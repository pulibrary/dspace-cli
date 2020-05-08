# Class decorating the Community Java Class
# @see https://github.com/DSpace/DSpace/blob/dspace-5.3/dspace-api/src/main/java/org/dspace/content/Community.java
class DCommunity

  # Find a child collection by its name
  # @param name [String]
  # @return [Array<org.dspace.content.DSpaceObject>]
  def find_collection_by_name(name)
    @obj.getCollections.select { |c| c.getName == name  }[0]
  end

  # Find or create a new child collection by its name
  # @param name [String]
  # @return [org.dspace.content.DSpaceObject]
  def find_or_create_collection_by_name(name)
    col = find_collection_by_name(name)
    if col.nil? then
      col = @obj.createCollection()
      col.setMetadataSingleValue("dc", "title", nil, nil, name)
      col.update
    end
    col
  end

  # Update the names of all workflow groups for the decorated DSObject
  # @return [org.dspace.content.DSpaceObject] the decorated community
  def name_workflow_groups
    @obj.getCollections.each { |col| DSpace.create(col).name_workflow_groups }
    self
  end

  # Update the names of all submitter groups for the decorated DSObject
  # @return [org.dspace.content.DSpaceObject] the decorated community
  def name_submitter_group
    @obj.getCollections.each { |col| DSpace.create(col).name_submitter_group }
    self
  end

  # For a given workflow step, find and create workflow groups using this workflow step for all child collections
  # @param step [String]
  # @return [Array<org.dspace.content.DSpaceObject>]
  def find_or_create_workflow_group(step)
    @obj.getCollections.collect { |col| DSpace.create(col).find_or_create_workflow_group(step) }
  end

  # Create DSpace Bitstreams on the decorated DSObject for a given bundle name
  # @see https://github.com/DSpace/DSpace/blob/dspace-5.3/dspace-api/src/main/java/org/dspace/content/Bundle.java
  # @see https://github.com/DSpace/DSpace/blob/dspace-5.3/dspace-api/src/main/java/org/dspace/content/Bitstream.java
  # @param bundleName [String]
  # @return [Array<org.dspace.content.Bitstream>]
  def bitstreams(bundleName = "ORIGINAL")
    bits = []
    @obj.getCollections.each do |col|
      bits += DSpace.create(col).bitstreams(bundleName)
    end
    bits
  end

end
