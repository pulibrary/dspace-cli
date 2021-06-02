# frozen_string_literal: true

module DSpace
  module CLI
    # This extends the JRuby models for DCollection
    class DCollection < ::DCollection
      java_import(org.dspace.content.Collection)

      def self.create(name, community)
        new_col = Java::OrgDspaceContent::Collection.create(DSpace.context)
        new_col.setMetadata('name', name)
        new_col.update
        community.addCollection(new_col)
        new_col
      end

      def initialize(dobj)
        super(dobj)
        @obj = dobj
      end

      # Create string for workflow naming convention (mainly for private use)
      def workflow_name(postfix)
        "#{@obj.getName}_#{postfix.to_s.upcase}"
      end

      # Create or find step of a Collection's workflow group. If "SUBMIT", then
      #   get submitters.
      def find_or_create_workflow_group(step)
        step = step.upcase
        if step.start_with?('STEP_')
          parts = step.split('_')
          i = parts[1].to_i
          group = @obj.getWorkflowGroup(i)
          if group.nil?
            group = DGroup.find_or_create(workflow_name(i.to_s))
            @obj.setWorkflowGroup(i, group)
          end
        elsif step == 'SUBMIT'
          @obj.createSubmitters
          name_submitter_group
          group = @obj.getSubmitters
        end
        @obj.update
        group
      end

      # Rename all workflows with preset "STEP_1", "STEP_2", "STEP_3" standardization
      def name_workflow_groups
        [1, 2, 3].each do |step|
          group = @obj.getWorkflowGroup(step)
          next unless group

          name = group.getName
          new_name = workflow_name(step) # I don't think this self is necessary
          if name != new_name
            group.setName(new_name)
            group.update
          end
        end

        self
      end

      # change workflow name of all submitters "SUBMIT"
      def name_submitter_group
        group = @obj.getSubmitters
        if group
          name = group.getName
          new_name = workflow_name('SUBMIT')
          if name != new_name
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
      def bitstreams(bundleName = 'ORIGINAL')
        bits = []

        iter = @obj.getItems
        while (i = iter.next)
          bits += DSpace.create(i).bitstreams(bundleName)
        end

        bits
      end

      # copy Collection into Jruby Community with the new name
      # When copying, include groups from submitters and workflow.
      def copy(name, parent)
        raise 'must give non nil parent community' if parent.nil?
        raise 'parent must be a community' if parent.getType != DConstants::COMMUNITY

        name = name.strip

        new_col = self.class.create(name, parent)

        group = @obj.getSubmitters
        if group
          new_group = new_col.createSubmitters
          copy_group(group, new_group)
        end

        [1, 2, 3].each do |i|
          group = @obj.getWorkflowGroup(i)
          if group
            new_group = new_col.createWorkflowGroup(i)
            copy_group(group, new_group)
          end
        end

        new_col.update
        new_col
      end

      private

      # copy subgroups and members from one group "from" to anther "to"
      def copy_group(from, to)
        sub_groups = from.getMemberGroups
        sub_groups.each do |g|
          to.addMember(g)
        end
        from.getMembers.each do |g|
          to.addMember(g)
        end
        to.update
      end
    end
  end
end
