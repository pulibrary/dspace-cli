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
        <<-SQL
        UPDATE handle
          SET handle = ?
          WHERE resource_id = ?
            AND handle = ?
        SQL
      end

      def self.insert_handle_statement
        <<-SQL
        INSERT INTO handle
          (handle_id, handle, resource_id)
          VALUES (?, ?, ?)
        SQL
      end

      def self.database_manager
        Java::OrgDspaceStorageRdbms::DatabaseManager
      end

      def self.update_table(statement, *params)
        database_manager.updateQuery(kernel.context, statement, *params)
      end

      def self.query(database_query, *params)
        database_manager.query(kernel.context, database_query, *params)
      end

      def update_handle(value)
        statement = self.class.update_handle_statement

        self.class.update_table(statement, value, id, handle)
        reload
      end

      def self.select_next_handle_id_query
        <<-SQL
        SELECT (handle_id + 1) AS next_handle_id FROM handle
          ORDER BY handle_id DESC
          LIMIT 1
        SQL
      end

      def self.select_handle_query
        <<-SQL
        SELECT handle FROM handle
          WHERE resource_id = ?
          LIMIT 1
        SQL
      end

      def self.select_next_handle_id
        select_query = select_next_handle_id_query

        results = query(select_query)
        row_iterator = results

        rows = []
        rows << row_iterator.next while row_iterator.hasNext

        return if rows.empty?

        row = rows.first
        value = row.getIntColumn('next_handle_id')
        value.to_i
      end

      def add_handle(value)
        statement = self.class.insert_handle_statement
        new_record_id = self.class.select_next_handle_id

        self.class.update_table(statement, new_record_id, value, id)
        reload
      end

      def select_handle
        select_query = self.class.select_handle_query

        results = self.class.query(select_query, id)
        row_iterator = results

        rows = []
        rows << row_iterator.next while row_iterator.hasNext

        return if rows.empty?

        row = rows.first
        value = row.getStringColumn('handle')
        value.to_s
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

      def self.community_class
        Community
      end

      def self.collection_class
        Collection
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
        # This is not reliable either
        # @obj.getHandle
        @obj.getHandle || select_handle
      end

      # This will never delete existing handles if set to nil
      def handle=(value)
        return if value.nil?

        if handle.nil?
          add_handle(value)
        else
          update_handle(value)
        end
      end

      def delete_handle
        nil
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

      def remove_from_index
        self.class.indexing_service.unIndexContent(self.class.kernel.context, @obj, true)
      end
    end
  end
end
