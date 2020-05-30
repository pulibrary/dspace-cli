##
# This class extends DCollection from the dspace jruby gem for Princeton-specific
# functionality.
# @see https://github.com/pulibrary/dspace-jruby
class DCollection

  # Create string for workflow naming convention (mainly for private use)
  def workflow_name(postfix)
    "#{@obj.getName}_#{postfix.to_s.upcase}"
  end

  # Create or find step of a Collection's workflow group. If "SUBMIT", then
  #   get submitters.
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

  # Rename all workflows with preset "STEP_1", "STEP_2", "STEP_3" standardization
  def name_workflow_groups
    colname = @obj.getName.gsub(/\s+/, '_')
    [1, 2, 3].each do |step|
      group = @obj.getWorkflowGroup(step)
      if (group) then
        name = group.getName
        new_name = self.workflow_name(step) # I don't think this self is necessary
        if (name != new_name) then
          puts "rename group #{name} -> #{new_name}"
          group.setName(new_name)
          group.update
        end
      end
    end
    self
  end

  # change workflow name of all submitters "SUBMIT"
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

  ##
  # Return all bitstreams within the collection.
  #
  # @param bundleName [String] 
  # @return [Array<org.dspace.content.Bitstream>] an array of Bitstream objects.
  def bitstreams(bundleName = "ORIGINAL")
    bits = []
    iter = @obj.getItems
    while (i = iter.next) do
      bits += DSpace.create(i).bitstreams(bundleName)
    end
    bits
  end

  # copy Collection into Jruby Community with the new name
  # When copying, include groups from submitters and workflow.
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
  # copy subgroups and members from one group "from" to anther "to"
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
