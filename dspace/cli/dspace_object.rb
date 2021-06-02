# frozen_string_literal: true

module DSpace
  module CLI
    # Class Modeling the Java Class org.dspace.content.DSpaceObject
    # @see https://github.com/DSpace/DSpace/blob/dspace-5.5/dspace-api/src/main/java/org/dspace/content/DSpaceObject.java
    class DSpaceObject
      java_import(org.dspace.content.DSpaceObject)
      java_import(org.dspace.handle.HandleManager)
      attr_reader :model

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

      def self.select_all_metadata_value_query
        <<-SQL
          SELECT metadata_field_id, text_value, text_lang FROM metadatavalue
            WHERE resource_id = ?
        SQL
      end

      def self.database_query
        org.dspace.storage.rdbms.DatabaseManager
      end

      def self.metadata_field_model
        org.dspace.content.MetadataField
      end

      def self.metadata_schema_model
        org.dspace.content.MetadataSchema
      end

      def metadata_database_rows
        return [] if @obj.nil?

        row_iterator = self.class.database_manager.query(self.class.kernel.context, self.class.select_all_metadata_value_query, id.to_java)

        rows = []
        rows << row_iterator.next while row_iterator.hasNext
        rows
      end

      def build_metadatum(schema, element, qualifier = nil, language = nil)
        metadata_field = self.class.find_metadata_field(schema, element, qualifier)

        CLI::Metadatum.build(self, metadata_field, element, qualifier, language)
      rescue StandardError => e
        warn("Failed to find the MetadataField record for #{schema}.#{element}.#{qualifier}")
        warn e.message
        warn e.backtrace.join("\n")
        nil
      end

      # Construct the Metadatum objects from database rows
      # @return [Array<Metadatum>]
      def build_metadata
        values = metadata_database_rows.map do |row|
          metadata_field_id = row.getIntColumn('metadata_field_id')
          metadata_field = self.class.metadata_field_model.find(self.class.kernel.context, metadata_field_id)

          schema_id = metadata_field.getSchemaID
          schema_model = self.class.metadata_schema_model.find(self.class.kernel.context, schema_id)

          schema = schema_model.getName
          element = metadata_field.getElement
          qualifier = metadata_field.getQualifier
          value = row.getStringColumn('text_value')
          language = row.getStringColumn('text_lang')

          new_metadatum = build_metadatum(schema, element, qualifier, language)

          new_metadatum.value = value unless new_metadatum.nil?
          new_metadatum
        end

        new_elements = values.reject(&:nil?)
        MetadataArray.new(new_elements)
      end

      def metadata
        @metadata ||= build_metadata
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

      def add_metadata(schema:, element:, value:, qualifier: nil, language: nil)
        new_metadatum = build_metadatum(schema, element, qualifier, language)
        return if new_metadatum.nil?

        new_metadatum.value = value
        @metadata.elements << new_metadatum
        new_metadatum
      end

      # This should be moved to DSpace::CLI::MetadataField
      # @param schema [String]
      # @param element [String]
      # @param qualifier [String]
      # @return [org.dspace.content.MetadataField]
      def self.find_metadata_field(schema, element, qualifier = nil)
        schema_model = Java::OrgDspaceContent::MetadataSchema.find(kernel.context, schema)
        raise "Failed to find the MetadataSchema record for #{schema} (#{schema.class})" if schema_model.nil?

        metadata_field_model.findByElement(kernel.context, schema_model.getSchemaID, element, qualifier)
      end

      def self.community_class
        CLI::Community
      end

      def self.item_class
        CLI::Item
      end

      def self.collection_class
        CLI::Collection
      end

      def self.metadata_field_class
        CLI::MetadataField
      end

      # Constructor
      # @param model [org.dspace.content.DSpaceObject]
      def initialize(model)
        @model = model
        # @obj is ambiguous, and I would like to see this deprecated
        @obj = @model
      end

      # This needs to be deprecated
      def obj
        @model
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
        raise NotImplementedError
      end

      def type_text
        @obj.getTypeText
      end

      def collections
        @obj.getCollections.map { |collection_obj| self.class.collection_class.new(collection_obj) }
      end

      def first_collection
        collections.first
      end

      def first_collection_title
        return if first_collection.nil?

        first_collection.title
      end

      # rubocop:disable Naming/MethodName
      def getMetadataByMetadataString(metadata_field)
        @model.getMetadataByMetadataString(metadata_field)
      end
      # rubocop:enable Naming/MethodName

      def get_metadata_value(field)
        metadata_models = @model.getMetadataByMetadataString(field.to_s)
        metadata_models.collect(&:value)
      end

      def self.register_metadata_field(field:, label:, plural_label: nil)
        # This should have pluralizer
        plural_label ||= "#{label}s"
        plural_method = plural_label.to_sym

        define_method(plural_method) do
          get_metadata_value(field)
        end

        define_method(label.to_sym) do
          values = send(plural_method)
          values.first
        end
      end

      def titles
        get_metadata_value(self.class.title_field)
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
        @model.update
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

      def self.handle_manager
        org.dspace.handle.HandleManager
      end

      def self.find_by_handle(handle)
        obj = handle_manager.resolveToObject(kernel.context, handle)
        return if obj.nil?

        new(obj)
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
