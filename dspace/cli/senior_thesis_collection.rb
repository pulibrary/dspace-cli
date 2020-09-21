module DSpace
  module CLI
    class SeniorThesisCollection < Collection
      # This needs to be restructured to parse a configuration file
      def self.department_to_collection_map
        {
          'Comparative Literature' => '88435/dsp01rf55z7763',
          'English' => '88435/dsp01qf85nb35s'
        }
      end

      def self.find_for_department(department)
        return unless department_to_collection_map.key?(department)

        handle = department_to_collection_map[department]
        obj = Java::OrgDspaceHandle::HandleManager.resolveToObject(kernel.context, handle)
        return if obj.nil?

        new(obj)
      end
    end
  end
end
