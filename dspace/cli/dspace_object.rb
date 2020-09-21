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

      def self.find_metadata_field(schema, element, qualifier = nil)
        schema_model = Java::OrgDspaceContent::MetadataSchema.find(kernel.context, schema)
        raise "Failed to find the MetadataSchema record for #{schema} (#{schema.class})" if schema_model.nil?

        Java::OrgDspaceContent::MetadataField.findByElement(kernel.context, schema_model.getSchemaID, element, qualifier)
      end

      def build_metadatum(schema, element, qualifier = nil, language = nil)
        metadata_field = self.class.find_metadata_field(schema, element, qualifier)

        DSpace::CLI::Metadatum.build(self, metadata_field, element, qualifier, language)
      rescue StandardError => e
        warn("Failed to find the MetadataField record for #{schema}.#{element}.#{qualifier}")
        warn e.message
        warn e.backtrace.join("\n")
        nil
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
