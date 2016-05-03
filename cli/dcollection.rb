class DCollection

  def find_or_create_workflow_group(step)
    step = step.upcase
    if (step.start_with?("STEP_")) then
      parts = step.split("_")
      i = parts[1].to_i
      group = @obj.getWorkflowGroup(i)
      if group.nil?  then
        group = DGroup.find_or_create("#{@obj.getName}_#{step}")
        @obj.setWorkflowGroup(i, group)
      end
    elsif (step == "SUBMIT") then
      @obj.createSubmitters();
      group = @obj.getSubmitters
      self.name_submitter_group
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
        new_name = "#{colname}_STEP_#{step}"
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
      new_name = "#{colname}_SUBMIT"
      if (name != new_name) then
        puts "rename group #{name} -> #{new_name}"
        group.setName(new_name)
        group.update
      end
    end
    self
  end
end