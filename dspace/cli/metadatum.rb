module DSpace
  module CLI
    # Class modeling Metadatum
    # @todo Implement support for the "place" int column values
    # @todo Implement support for the "authority" string column values
    # @todo Implement support for the "confidence" int column values
    class Metadatum
      java_import org.dspace.storage.rdbms.DatabaseManager
      java_import org.dspace.content.MetadataField
      java_import org.dspace.content.Metadatum
      java_import org.dspace.core.Constants

      attr_reader :model

      def initialize(model, metadata_field, item)
        @model = model
        @obj = @model

        @text_value = @model.value
        @text_lang = @model.language

        @metadata_field_id = metadata_field.getFieldID unless metadata_field.nil?

        @item = item
        @item_id = item.id
      end

      def id
        @model.getValueId
      end

      def value=(val)
        @text_value = val
        @model.value = val
      end

      def value
        @text_value
      end

      def language=(val)
        @text_lang = val
        @model.language = val
      end

      def language
        @text_lang
      end

      def schema_id
        metadata_field.schema_id
      end

      def schema
        Java::OrgDspaceContent::MetadataSchema.find(self.class.kernel.context, schema_id)
      end

      def element
        metadata_field.element
      end

      def qualifier
        metadata_field.qualifier
      end

      def self.build(item, metadata_field, element, qualifier = nil, language = nil)
        obj = Java::OrgDspaceContent::Metadatum.new
        obj.element = element
        obj.qualifier = qualifier
        obj.language = language

        new(obj, metadata_field, item)
      end

      def self.find(item_id, metadata_field_id, text_value)
        item = Java::OrgDspaceContent::Item.find(self.class.kernel, item_id)
        metadata_field = Java::OrgDspaceContent::MetadataField.find(self.class.kernel, metadata_field_id)

        obj = Java::OrgDspaceContent::Metadatum.new
        obj.element = metadata_field.getElement
        obj.qualifier = metadata_field.getQualifier
        obj.value = text_value

        new(obj, metadata_field, item)
      end

      def self.kernel
        DSpace
      end

      def self.table_name
        'MetadataValue'
      end

      # This cannot be used due to some issues between the splat operator and Java varargs
      def self.query_table(query, *params)
        Java::OrgDspaceStorageRdbms::DatabaseManager.query(kernel.context, query, *params)
      end

      def self.select_query
        'SELECT * FROM metadatavalue AS v WHERE v.metadata_value_id = ?'
      end

      def self.select_language_query
        'SELECT * FROM MetadataValue WHERE resource_id = ? AND metadata_field_id = ? AND text_value = ? AND text_lang = ?'
      end

      def self.select_value_query
        'SELECT * FROM MetadataValue WHERE resource_id = ? AND metadata_field_id = ? AND text_value = ?'
      end

      def self.update_language_query
        'UPDATE MetadataValue SET text_value = ?, text_lang = ? WHERE resource_id = ? AND metadata_field_id = ?'
      end

      def self.update_value_query
        'UPDATE MetadataValue SET text_value = ? WHERE resource_id = ? AND metadata_field_id = ?'
      end

      def self.insert_language_query
        'INSERT INTO MetadataValue (resource_id, resource_type_id, metadata_field_id, text_value, text_lang) VALUES (?, ?, ?, ?, ?)'
      end

      def self.insert_value_query
        'INSERT INTO MetadataValue (resource_id, resource_type_id, metadata_field_id, text_value) VALUES (?, ?, ?, ?)'
      end

      def self.delete_language_query_limit
        <<-SQL
          DELETE FROM MetadataValue AS t1
            WHERE t1.resource_id = ? AND t1.metadata_field_id = ? AND t1.text_value = ? AND t1.text_lang = ?
            AND t1.ctid = (
              SELECT t2.ctid FROM MetadataValue AS t2
              WHERE t2.resource_id = ? AND t2.metadata_field_id = ? AND t2.text_value = ? AND t2.text_lang = ?
              LIMIT 1
            )
        SQL
      end

      def self.delete_language_query
        <<-SQL
          DELETE FROM MetadataValue AS t1
            WHERE t1.resource_id = ? AND t1.metadata_field_id = ? AND t1.text_value = ? AND t1.text_lang = ?
        SQL
      end

      def self.delete_value_query_limit
        <<-SQL
          DELETE FROM MetadataValue AS t1
            WHERE t1.resource_id = ? AND t1.metadata_field_id = ? AND t1.text_value = ?
            AND t1.ctid = (
              SELECT t2.ctid FROM MetadataValue AS t2
              WHERE t2.resource_id = ? AND t2.metadata_field_id = ? AND t2.text_value = ?
              LIMIT 1
            )
        SQL
      end

      def self.delete_value_query
        <<-SQL
          DELETE FROM MetadataValue AS t1
            WHERE t1.resource_id = ? AND t1.metadata_field_id = ? AND t1.text_value = ?
        SQL
      end

      def self.delete_query
        <<-SQL
          DELETE FROM metadatavalue AS v
            WHERE v.metadata_value_id = ?
        SQL
      end

      def self.delete_all_from_database(item_id, metadata_field_id, text_value, text_lang)
        lang = text_lang.nil? ? '' : text_lang
        connection = kernel.context.getDBConnection

        if lang.empty?
          database_query = delete_value_query
          statement = connection.prepareStatement(database_query)
          statement.setInt(1.to_java.intValue, item_id.to_java.intValue)
          statement.setInt(2.to_java.intValue, metadata_field_id.to_java.intValue)
          statement.setString(3.to_java.intValue, text_value)
        else
          database_query = delete_language_query
          statement = connection.prepareStatement(database_query)
          statement.setInt(1.to_java.intValue, item_id.to_java.intValue)
          statement.setInt(2.to_java.intValue, metadata_field_id.to_java.intValue)
          statement.setString(3.to_java.intValue, text_value)
          statement.setString(4.to_java.intValue, lang)
        end

        statement.executeUpdate
        statement.close
        connection.commit
      end

      def self.update_table(query, *params)
        Java::OrgDspaceStorageRdbms::DatabaseManager.updateQuery(kernel.context, query, *params)
      end

      def self.select_from_database(id:)
        database_manager.query(kernel.context, select_query, id)
      end

      def self.select_from_database_dep(item_id, metadata_field_id, text_value, text_lang)
        lang = text_lang.nil? ? '' : text_lang

        if lang.empty?
          database_query = select_value_query
          Java::OrgDspaceStorageRdbms::DatabaseManager.query(kernel.context, database_query, item_id.to_java, metadata_field_id.to_java, text_value)
        else
          database_query = select_language_query
          Java::OrgDspaceStorageRdbms::DatabaseManager.query(kernel.context, database_query, item_id.to_java, metadata_field_id.to_java, text_value, lang)
        end
      end

      def self.update_in_database(id:, text_value:, resource_id:, metadata_field_id:, text_lang: nil)
        update_params = [id.to_java, resource_id.to_java, metadata_field_id.to_java, text_value]
        database_statement = if text_lang.nil? || text_lang.empty?
                               update_value_query
                             else
                               update_language_query
                               update_params << text_lang
                             end

        database_manager.updateQuery(kernel.context, database_statement, *update_params)
      end

      def self.create_in_database(resource_id:, metadata_field_id:, text_value:, text_lang:)
        update_params = [resource_id.to_java, Java::OrgDspaceCore::Constants::ITEM, metadata_field_id.to_java, text_value]
        database_statement = if text_lang.nil? || text_lang.empty?
                               insert_value_query
                             else
                               insert_language_query
                               update_params << text_lang
                             end

        database_manager.updateQuery(kernel.context, database_statement, *update_params)
      end

      def self.database_manager
        org.dspace.storage.rdbms.DatabaseManager
      end

      def self.delete_from_database(id:)
        database_statement = delete_query
        database_manager.updateQuery(kernel.context, database_statement, id)
      end

      def self.delete_from_database_deprecated(item_id, metadata_field_id, text_value, text_lang)
        lang = text_lang.nil? ? '' : text_lang

        connection = kernel.context.getDBConnection

        if lang.empty?
          database_query = delete_value_query_limit
          statement = connection.prepareStatement(database_query)

          statement.setInt(1.to_java.intValue, item_id.to_java.intValue)
          statement.setInt(2.to_java.intValue, metadata_field_id.to_java.intValue)
          statement.setString(3.to_java.intValue, text_value)
          statement.setInt(4.to_java.intValue, item_id.to_java.intValue)
          statement.setInt(5.to_java.intValue, metadata_field_id.to_java.intValue)
          statement.setString(6.to_java.intValue, text_value)
        else
          database_query = delete_language_query_limit

          statement = connection.prepareStatement(database_query)
          statement.setInt(1.to_java.intValue, item_id.to_java.intValue)
          statement.setInt(2.to_java.intValue, metadata_field_id.to_java.intValue)
          statement.setString(3.to_java.intValue, text_value)
          statement.setString(4.to_java.intValue, lang)

          statement.setInt(5.to_java.intValue, item_id.to_java.intValue)
          statement.setInt(6.to_java.intValue, metadata_field_id.to_java.intValue)
          statement.setString(7.to_java.intValue, text_value)
          statement.setString(8.to_java.intValue, lang)
        end

        statement.executeUpdate
        statement.close
        connection.commit
      end

      def database_row
        row_iterator = self.class.select_from_database(id: id)
        return if row_iterator.nil?

        # This does not disambiguate between the "dc" and "dcterms" schema
        # As a result, duplicate metadata are generated
        if !row_iterator.hasNext && metadata_field_id == 2
          row_iterator = self.class.select_from_database(item_id, 3, @text_value, @text_lang)
          return if row_iterator.nil?
        end

        rows = []
        rows << row_iterator.next while row_iterator.hasNext

        rows.first
      end

      def persisted?
        !database_row.nil?
      end

      def create
        return if persisted?

        self.class.create_in_database(resource_id: item_id, metadata_field_id: metadata_field_id, text_value: value, text_lang: language)
      end

      def update
        return create unless persisted?

        self.class.update_in_database(id: id, text_value: value, text_lang: language, resource_id: item_id, metadata_field_id: metadata_field_id)
      end

      def delete
        self.class.delete_from_database(id: id)
      end

      def delete_all_models
        self.class.delete_all_from_database(item_id, metadata_field_id, @text_value, @text_lang)
      end

      def metadata_field_id
        @metadata_field_id ||= database_row.getIntColumn('metadata_field_id')
      end

      def build_metadata_field
        dspace_model = Java::OrgDspaceContent::MetadataField.find(self.class.kernel.context, metadata_field_id)
        DSpace::CLI::MetadataField.build(model: dspace_model)
      end

      def metadata_field
        @metadata_field ||= build_metadata_field
      end

      # This should not be an alias
      def field
        metadata_field
      end

      def item_id
        @item_id ||= database_row.getIntColumn('item_id')
      end

      def item
        @item ||= Java::OrgDspaceContent::Item.find(self.class.kernel, item_id)
      end

      def matches_field?(metadatum)
        metadata_field_id == metadatum.metadata_field_id
      end

      def ==(metadatum)
        matches = matches_field?(metadatum)

        matches &&= @text_value == metadatum.value
        # matches &&= @text_lang == metadatum.language

        text_lang_value = @text_lang.nil? ? '' : @text_lang
        compared_text_lang_value = metadatum.language.nil? ? '' : metadatum.language
        matches &&= text_lang_value == compared_text_lang_value

        matches
      end
    end
  end
end
