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

      def initialize(obj, metadata_field, item)
        @obj = obj
        @text_value = @obj.value
        @text_lang = @obj.language

        @metadata_field = metadata_field
        @metadata_field_id = metadata_field.getFieldID

        @item = item
        @item_id = item.id
      end

      def value=(val)
        @text_value = val
        @obj.value = val
      end

      def value
        @text_value
      end

      def language=(val)
        @text_lang = val
        @obj.language = val
      end

      def language
        @text_lang
      end

      def schema_id
        metadata_field.schemaID
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

      def self.delete_language_query
        'DELETE FROM MetadataValue WHERE resource_id = ? AND metadata_field_id = ? AND text_value = ? AND text_lang = ?'
      end

      def self.delete_value_query
        'DELETE FROM MetadataValue WHERE resource_id = ? AND metadata_field_id = ? AND text_value = ?'
      end

      def self.update_table(query, *params)
        Java::OrgDspaceStorageRdbms::DatabaseManager.updateQuery(kernel.context, query, *params)
      end

      def self.select_from_database(item_id, metadata_field_id, text_value, text_lang)
        lang = text_lang.nil? ? '' : text_lang

        if lang.empty?
          database_query = select_value_query

          Java::OrgDspaceStorageRdbms::DatabaseManager.query(kernel.context, database_query, item_id.to_java, metadata_field_id.to_java, text_value)
        else
          database_query = select_language_query
          Java::OrgDspaceStorageRdbms::DatabaseManager.query(kernel.context, database_query, item_id.to_java, metadata_field_id.to_java, text_value, lang)
        end
      end

      def self.update_in_database(text_value, text_lang, item_id, metadata_field_id)
        lang = text_lang.nil? ? '' : text_lang

        if lang.empty?
          database_query = update_value_query
          Java::OrgDspaceStorageRdbms::DatabaseManager.updateQuery(kernel.context, database_query, text_value, item_id.to_java, metadata_field_id.to_java)
        else
          database_query = update_language_query
          Java::OrgDspaceStorageRdbms::DatabaseManager.updateQuery(kernel.context, database_query, text_value, lang, item_id.to_java, metadata_field_id.to_java)
        end
      end

      def self.create_in_database(item_id, metadata_field_id, text_value, text_lang)
        lang = text_lang.nil? ? '' : text_lang

        if lang.empty?
          database_query = insert_value_query
          Java::OrgDspaceStorageRdbms::DatabaseManager.updateQuery(kernel.context, database_query, item_id.to_java, Java::OrgDspaceCore::Constants::ITEM, metadata_field_id.to_java, text_value)
        else
          database_query = insert_language_query
          Java::OrgDspaceStorageRdbms::DatabaseManager.updateQuery(kernel.context, database_query, item_id.to_java, Java::OrgDspaceCore::Constants::ITEM, metadata_field_id.to_java, text_value, lang)
        end
      end

      def self.delete_from_database(item_id, metadata_field_id, text_value, text_lang)
        lang = text_lang.nil? ? '' : text_lang

        if lang.empty?
          database_query = delete_value_query
          Java::OrgDspaceStorageRdbms::DatabaseManager.updateQuery(kernel.context, database_query, item_id.to_java, metadata_field_id.to_java, text_value)
        else
          database_query = delete_language_query
          Java::OrgDspaceStorageRdbms::DatabaseManager.updateQuery(kernel.context, database_query, item_id.to_java, metadata_field_id.to_java, text_value, lang)
        end
      end

      def database_row
        row_iterator = self.class.select_from_database(item_id, metadata_field_id, @text_value, @text_lang)
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

      def update
        if persisted?
          self.class.update_in_database(@text_value, @text_lang, item_id, metadata_field_id)
        else
          self.class.create_in_database(item_id, metadata_field_id, @text_value, @text_lang)
        end
      end

      def delete
        self.class.delete_from_database(item_id, metadata_field_id, @text_value, @text_lang)
      end

      def metadata_field_id
        @metadata_field_id ||= database_row.getIntColumn('metadata_field_id')
      end

      def metadata_field
        @metadata_field ||= Java::OrgDspaceContent::MetadataField.find(self.class.kernel, metadata_field_id)
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
