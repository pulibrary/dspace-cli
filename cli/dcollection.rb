class DCollection

  def workflow_name(postfix)
    "#{@obj.getName}_#{postfix.upcase}"
  end

  def find_or_create_workflow_group(step)
    step = step.upcase
    if (step.start_with?("STEP_")) then
      parts = step.split("_")
      i = parts[1].to_i
      group = @obj.getWorkflowGroup(i)
      if group.nil?  then
        group = DGroup.find_or_create(workflow_name(step))
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

  def getBitstreams(bundleName = "ORIGINAL")
    bits = []
    iter = @obj.getItems
    while (i = iter.next) do
      bits += DSpace.create(i).getBitstreams(bundleName)
    end
    bits
  end

end