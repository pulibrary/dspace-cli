# @abstract Decorator pattern for org.dspace.content.DSpaceObject instances
class DCollection

  # Generate the name of the workflow database table
  # @param postfix [String] the suffix for the table name
  # @return [String]
  def workflow_name(postfix)
    "#{@obj.getName}_#{postfix.to_s.upcase}"
  end

  # Find or create the DGroup associated with the workflow for the decorated DSObject
  # @param step [String] the name of the workflow step
  # @return [DSGroup]
  def find_or_create_workflow_group(step)
    step = step.upcase
    if (step.start_with?("STEP_")) then
      parts = step.split("_")
      i = parts[1].to_i
      group = @obj.getWorkflowGroup(i)
      if group.nil? then
        group = DGroup.find_or_create(workflow_name(i.to_s))
        @obj.setWorkflowGroup(i, group)
      end
    elsif (step == "SUBMIT") then
      @obj.createSubmitters();
      name_submitter_group
      group = @obj.getSubmitters
    end
    @obj.update
    group
  end

  # Update the name of the workflow DGroups to which the decorated DSObject belongs with an updated workflow step name
  # @note This is for case where the workflow steps for the Collection has been updated, but the workflow groups have not had their names to reflect these updates
  # @return [DCollection] this object
  def name_workflow_groups
    colname = @obj.getName.gsub(/\s+/, '_')
    [1, 2, 3].each do |step|
      group = @obj.getWorkflowGroup(step)
      if (group) then
        name = group.getName
        new_name = self.workflow_name(step)
        if (name != new_name) then
          puts "rename group #{name} -> #{new_name}"
          group.setName(new_name)
          group.update
        end
      end
    end
    self
  end

  # Update the name of the submitter DGroups to which the decorated DSObject belongs with an updated workflow step name
  # @note This is for case where the workflow steps for the Collection has been updated, but the submitter groups have not had their names to reflect these updates
  # @return [DCollection] this object
  def name_submitter_group
    colname = @obj.getName.gsub(/\s+/, '_')
    group = @obj.getSubmitters
    if (group) then
      name = group.getName
      new_name = workflow_name("SUBMIT")
      if (name != new_name) then
        puts "rename group #{name} -> #{new_name}"
        group.setName(new_name)
        group.update
      end
    end
    self
  end

  # Create DSpace Bitstreams on the decorated DSObject for a given bundle name
  # @see https://github.com/DSpace/DSpace/blob/dspace-5.3/dspace-api/src/main/java/org/dspace/content/Bundle.java
  # @see https://github.com/DSpace/DSpace/blob/dspace-5.3/dspace-api/src/main/java/org/dspace/content/Bitstream.java
  # @param bundleName [String]
  # @return [Array<org.dspace.content.Bitstream>]
  def bitstreams(bundleName = "ORIGINAL")
    bits = []
    iter = @obj.getItems
    while (i = iter.next) do
      bits += DSpace.create(i).bitstreams(bundleName)
    end
    bits
  end

  # Copies the decorate Collection DSObject within a Community with a new name
  # @note this copies the submitter and workflow groups to the new collection
  # @param name [String]
  # @param parent [org.dspace.content.DSpaceObject]
  # @return [DCollection] the new collection
  def copy(name, parent)
    raise "must give non nil parent community" if parent.nil?
    raise "parent must be a community" if parent.getType != DConstants::COMMUNITY
    name = name.strip();

    puts "copying\t\t#{@obj} #{@obj.getName()}"
    puts "copying into\t#{parent} #{parent.getName()}"
    puts "naming it \t'#{name}'"

    new_col = DCollection.create(name, parent)
    puts "Created #{new_col.getHandle()}"

    group = @obj.getSubmitters
    if (group) then
      new_group = new_col.createSubmitters
      copy_group(group, new_group)
    end

    [1, 2, 3].each do |i|
      group = @obj.getWorkflowGroup(i)
      if (group) then
        new_group = new_col.createWorkflowGroup(i)
        copy_group(group, new_group)
      end
    end

    puts "default authorization left in place";

    new_col.update()
    return new_col
  end

  private

  # This copies a DSpace Groups and Persons from one DSObject to another
  # @note this ensures that sub-groups and each group member is copied to the target DSObject
  # @param from [org.dspace.content.DSpaceObject]
  # @param to [org.dspace.content.DSpaceObject]
  # @return [org.dspace.content.DSpaceObject]
  def copy_group(from, to)
    puts "create group #{to.getName()} based on #{from.getName()}"
    sub_groups = from.getMemberGroups()
    sub_groups.each do |g|
      puts "#{to.getName()}: add #{g.getName()}"
      to.addMember(g);
    end
    from.getMembers().each do |g|
      puts "#{to.getName()}: add #{g.getName()}"
      to.addMember(g);
    end
    to.update
  end
end
