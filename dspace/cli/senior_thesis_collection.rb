module DSpace
  module CLI
    class SeniorThesisCollection < Collection
      # This needs to be restructured to parse a configuration file
      def self.department_to_collection_map
        {}
      end

      # This needs to be restructured to parse a configuration file
      def self.certificate_to_collection_map
        {
          'Creative Writing Program' => '88435/dsp01gx41mh91n',
        }
      end

      def self.find_for_department(department)
        return unless department_to_collection_map.key?(department)

        handle = department_to_collection_map[department]
        obj = Java::OrgDspaceHandle::HandleManager.resolveToObject(kernel.context, handle)
        return if obj.nil?

        new(obj)
      end

      def self.find_for_handle(handle)
        obj = Java::OrgDspaceHandle::HandleManager.resolveToObject(kernel.context, handle)
        return if obj.nil?

        new(obj)
      end

      def self.find_for_certificate(certificate)
        return unless certificate_to_collection_map.key?(certificate)

        handle = certificate_to_collection_map[certificate]
        obj = Java::OrgDspaceHandle::HandleManager.resolveToObject(kernel.context, handle)
        return if obj.nil?

        new(obj)
      end
    end
  end
end
