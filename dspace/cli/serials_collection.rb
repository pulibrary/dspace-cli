module DSpace
  module CLI
    class SerialsCollection < Collection
      # This needs to be restructured to parse a configuration file
      def self.private_community_handle
        '88435/dsp01r781wg06f'
      end

      def self.public_community_handle
        '88435/dsp01kh04dp74g'
      end

      def self.community
        raise NotImplementedError
      end

      def self.kernel
        ::DSpace
      end

      def self.template_collection_handle
        '88435/dsp018c97kq48z'
      end

      def self.template_collection_model
        kernel.fromString(template_collection_handle)
      end

      # Is this needed?
      def self.template_collection
        new(template_collection_model)
        DSpace::CLI::DCollection.new(template_collection_model)
      end

      def self.create_template
        new(template_collection)
        DSpace::CLI::DCollection.new(template_collection_model)
      end

      def self.create_from_template(name:)
        template = create_template
        model = template.copy(name, community)
        new(model)
      end

      def copy(name:, parent:)
        raise 'Parent object must be a community' if parent.getType != ::DConstants::COMMUNITY

        collection_name = name.strip
        new_col = DSpace::CLI::DCollection.create(collection_name, parent)

        submitter_group = @obj.getSubmitters
        unless submitter_group.nil?
          new_group = new_col.createSubmitters
          copy_group(submitter_group, new_group)
        end

        [1, 2, 3].each do |i|
          wf_group = @obj.getWorkflowGroup(i)
          unless wf_group.nil?
            new_wf_group = new_col.createWorkflowGroup(i)
            copy_group(wf_group, new_wf_group)
          end
        end

        new_col.update
        new_col
      end
    end

    private

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
