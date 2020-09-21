# frozen_string_literal: true

module DSpace
  module CLI
    class DSpaceObject
      attr_reader :obj

      def self.kernel
        ::DSpace
      end

      def self.title_field
        MetadataField.new('dc', 'title')
      end

      def initialize(obj)
        @obj = obj
      end

      def id
        @obj.getID
      end

      def handle
        @obj.getHandle
      end

      def type_text
        @obj.getTypeText
      end

      # This needs to be abstracted
      # rubocop:disable Naming/MethodName
      def getMetadataByMetadataString(metadata_field)
        @obj.getMetadataByMetadataString(metadata_field)
      end
      # rubocop:enable Naming/MethodName

      def titles
        @obj.getMetadataByMetadataString(self.class.title_field.to_s).collect(&:value)
      end

      def title
        titles.first
      end

      def title=(value)
        clear_metadata('dc', 'title')
        update
        add_metadata('dc', 'title', value)
        update
        self.class.kernel.commit
      end

      def update
        @obj.update
        self.class.kernel.commit
      end

      def persisted?
        !@obj.nil?
      end

      def self.service_manager
        kernel.getServiceManager
      end

      def self.get_service_by_name(class_name, service_class)
        service_manager.getServiceByName(class_name, service_class)
      end

      def self.indexing_service
        get_service_by_name('org.dspace.discovery.SearchService', Java::OrgDspaceDiscovery::IndexingService)
      end

      def index
        self.class.indexing_service.indexContent(self.class.kernel.context, @obj, true)
      end
    end
  end
end
