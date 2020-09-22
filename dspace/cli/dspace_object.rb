# frozen_string_literal: true

module DSpace
  module CLI
    class DSpaceObject
      java_import(org.dspace.content.DSpaceObject)
      attr_reader :obj

      def self.kernel
        ::DSpace
      end

      def self.title_field
        MetadataField.new('dc', 'title')
      end

      def self.update_handle_statement
        'UPDATE handle SET handle = ? WHERE resource_id = ? AND handle = ?'
      end

      def self.insert_handle_statement
        'INSERT INTO handle (handle, resource_id) VALUES (?, ?)'
      end

      def self.update_table(query, *params)
        Java::OrgDspaceStorageRdbms::DatabaseManager.updateQuery(kernel.context, query, *params)
      end

      def update_handle(value)
        statement = update_handle_statement

        update_table(statement, value, id, handle)
      end

      def add_handle(value)
        statement = insert_handle_statement

        update_table(statement, value, id)
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

      def type
        @obj.getType
      end

      def reload
        persisted_type = type
        persisted_id = id

        @obj = nil
        reloaded = Java::OrgDspaceContent::DSpaceObject.find(self.class.kernel.context, persisted_type, persisted_id)
        @obj = reloaded
      end

      def handle
        @obj.getHandle
      end

      def handle=(value)
        if handle.nil?
          update_handle(value)
        else
          add_handle(value)
        end
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
