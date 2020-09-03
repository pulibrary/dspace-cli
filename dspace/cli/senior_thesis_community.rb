module DSpace
  module CLI
    class SeniorThesisCollection
      attr_reader :obj

      def self.kernel
        ::DSpace
      end

      def initialize(obj)
        @obj = obj
      end

      def removeItem(item)
        @obj.removeItem(item.obj)
      end

      def update
        @obj.update
        self.class.kernel.commit
      end
    end

    class SeniorThesisWorkflowItem
      attr_reader :obj

      def self.kernel
        ::DSpace
      end

      # This is some internal bug; I am not certain why I cannot use this from DItem
      def initialize(obj)
        @obj = obj
      end

      def delete
        @obj.deleteWrapper
        self.class.kernel.commit
        @obj = nil
      end
    end

    class Metadatum
      java_import org.dspace.storage.rdbms.DatabaseManager
      java_import org.dspace.content.MetadataField
      java_import org.dspace.content.Metadatum

      attr_reader :text_value, :text_lang

      def initialize(obj, metadata_field, item)
        @obj = obj
        @text_value = @obj.value
        @text_lang = @obj.language

        @metadata_field = metadata_field
        @metadata_field_id = metadata_field.getID

        @item = item
        @item_id = item.getID
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

      def self.build(item, metadata_field, element, qualifier = nil, language = nil)
        obj = Java::OrgDspaceContent::Metadatum.new
        obj.element = element
        obj.qualifier = qualifier
        obj.language = language

        self.new(obj, metadata_field, item)
      end

      def self.find(item_id, metadata_field_id, text_value)
        item = Java::OrgDspaceContent::Item.find(self.class.kernel, item_id)
        metadata_field = Java::OrgDspaceContent::MetadataField.find(self.class.kernel, metadata_field_id)

        obj = Java::OrgDspaceContent::Metadatum.new
        obj.element = metadata_field.getElement
        obj.qualifier = metadata_field.getQualifier
        obj.value = text_value

        self.new(obj, metadata_field, item)
      end

      def self.kernel
        DSpace
      end

      def self.table_name
        "MetadataValue"
      end

      def self.select_query
        "SELECT * FROM MetadataValue WHERE resource_id = ? ORDER BY metadata_field_id, place"
      end

      def self.query_table(query, *params)
        DatabaseManager.queryTable(kernel.context, table_name, query, *params)
      end

      def self.update_query
        "UPDATE MetadataValue SET (text_value, text_lang) = (?, ?) WHERE resource_id = ? AND metadata_field_id = ?"
      end

      def self.insert_query
        "INSERT INTO MetadataValue (item_id, metadata_field_id, text_value, text_lang) VALUES (?, ?, ?, ?)"
      end

      def self.update_table(query, *params)
        DatabaseManager.updateQuery(kernel.context, table_name, query, *params)
      end

      def self.select_from_database(item_id)
        query_table(select_query, item_id)
      end

      def self.update_in_database(text_value, text_lang, item_id, metadata_field_id)
        update_table(update_query, text_value, text_lang, item_id, metadata_field_id)
      end

      def self.create_in_database(item_id, metadata_field_id, text_value, text_lang)
        update_table(insert_query, item_id, metadata_field_id, text_value, text_lang)
      end

      def database_row
        row_iterator = self.class.select_from_database(item_id)
        return if row_iterator.nil?

        rows = []
        while(row_iterator.hasNext)
          rows << row_iterator.next
        end

        rows.first
      end

      def persisted?
        !database_row.nil?
      end

      def save
        if persisted?
          self.class.update_in_database(@text_value, @text_lang, item_id, metadata_field_id)
        else
          self.class.create_in_database(item_id, metadata_field_id, @text_value, @text_lang)
        end
      end

      def delete
        self.class.delete_from_database(@text_value, @text_lang, item_id, metadata_field_id)
      end

      def metadata_field_id
        @metadata_field_id ||= database_row.getIntColumn("metadata_field_id")
      end

      def metadata_field
        @metadata_field ||= Java::OrgDspaceContent::MetadataField.find(self.class.kernel, metadata_field_id)
      end

      def item_id
        @item_id ||= database_row.getIntColumn("item_id")
      end

      def item
        @item ||= Java::OrgDspaceContent::Item.find(self.class.kernel, item_id)
      end

      def matches_field?(metadatum)
=begin
        matches = false
        matches = matches |= self.metadata_field.getSchemaID == metadatum.metadata_field.getSchemaID
        matches = matches |= self.metadata_field.getElement == metadatum.metadata_field.getElement
        matches = matches |= self.metadata_field.getQualifier == metadatum.metadata_field.getQualifier
        matches
=end
        metadata_field_id == metadatum.metadata_field_id
      end

      def ==(metadatum)
        matches = matches_field?(metadatum)

        matches = matches |= @text_value == metadatum.text_value
        matches = matches |= @text_lang == metadatum.text_lang
        matches
      end

=begin
          tr.getIntColumn("place")
          tr.getStringColumn("text_value")
          tr.getStringColumn("text_lang")

          tr.getStringColumn("authority")
          tr.getIntColumn("confidence")
=end
    end

    class SeniorThesisItem < ::DItem
      java_import org.dspace.workflow.WorkflowItem
      java_import org.dspace.content.Metadatum
      java_import org.dspace.content.MetadataField
      java_import org.dspace.content.MetadataSchema

      attr_reader :obj

      def self.kernel
        ::DSpace
      end

      # This is some internal bug; I am not certain why I cannot use this from DItem
      def initialize(obj)
        @obj = obj
      end

      # This is some internal bug; I am not certain why I cannot use this from DItem
      def getMetadataByMetadataString(metadata_field)
        @obj.getMetadataByMetadataString(metadata_field)
      end

      def self.find_metadata_field(schema, element, qualifier = nil)
        schema_model = Java::OrgDspaceContent::MetadataSchema.find(kernel.context, schema)
        Java::OrgDspaceContent::MetadataField.findByElement(kernel.context, schema_model.getID, element, qualifier)
      end

      def build_metadatum(schema, element, qualifier = nil, language = nil)
        metadata_field = self.class.find_metadata_field(schema, element, qualified)
        DSpace::CLI::Metadatum.build(self, metadata_field, element, qualifier, language)
      end

      # I am not certain that this is needed
      def get_metadata
        values = @obj.getMetadata
        list = Utils::ArrayList.new(values)
        list.to_a
      end

      def save
        @metadata.each(&:save)
        @obj.save
        self.class.kernel.commit
        self
      end

      def add_metadata(schema, element, value, qualifier = nil, language = nil)
        new_metadatum = self.class.build_metadatum(schema, element, qualifier, language)
        @metadata << new_metadatum
        new_metadatum
      end

      def remove_metadata(schema, element, value, qualifier = nil, language = nil)
        new_metadatum = self.class.build_metadatum(schema, element, qualifier, language)
        new_metadatum.value = value
        new_metadatum.language = language

        updated_metadata = []
        metadata.each do |metadatum|
          if metadatum == new_metadatum
            metadatum.delete
          else
            updated_metadata << metadatum
          end
        end

        @metadata = updated_metadata
      end

      # I am not certain that this is needed
      class Java::OrgDspaceContent::DSpaceObject::MetadataCache
        attr_reader :metadata

        def initialize(metadata)
          @metadata = metadata
        end
      end

      # I am not certain that this is needed
      class Java::OrgDspaceContent::Item
        field_accessor :metadataCache
        field_accessor :modifiedMetadata
      end

      # I am not certain that this is needed
      def set_metadata(values)
        list = java.util.ArrayList.new(values)
        cache = Java::OrgDspaceContent::DSpaceObject::MetadataCache.new(list)
        @obj.metadataCache = cache
        @obj.modifiedMetadata = true
      end

      def clear_metadata(schema, element, qualifier = nil, language = nil)
        new_metadatum = self.class.build_metadatum(schema, element, qualifier, language)

        updated_metadata = []
        metadata.each do |metadatum|
          if metadatum.matches_field?(new_metadatum)
            metadatum.delete
          else
            updated_metadata << metadatum
          end
        end
        @metadata = updated_metadata
      end

      def id
        @obj.getID
      end

      def handle
        @obj.getHandle
      end

      def self.title_field
        Metadata::Field.new('dc', 'title')
      end

      def titles
        @obj.getMetadataByMetadataString(self.class.title_field.to_s).collect { |v| v.value }
      end

      def title
        titles.first
      end

      def self.department_field
        Metadata::Field.new('pu', 'department')
      end

      def departments
        @obj.getMetadataByMetadataString(self.class.department_field.to_s).collect { |v| v.value }
      end

      def department
        departments.first
      end

      def persisted?
        !@obj.nil?
      end

      def self.workflow_item_class
        SeniorThesisWorkflowItem
      end

      def self.collection_class
        SeniorThesisCollection
      end

      def workflow_item
        workflow_obj = Java::OrgDspaceWorkflow::WorkflowItem.findByItem(self.class.kernel.context, @obj)
        return if workflow_obj.nil?

        self.class.workflow_item_class.new(workflow_obj)
      end

      def collections
        @obj.getCollections.map { |collection_obj| self.class.collection_class.new(collection_obj) }
      end

      def delete
        workflow_item.delete unless workflow_item.nil?
        collections.each do |collection|
          collection.removeItem(self)
          collection.update
        end

        @obj.delete
        self.class.kernel.commit
        @obj = nil
      end
    end

    class SeniorThesisQuery
      java_import org.dspace.content.Item
      attr_reader :results, :parent

      def self.kernel
        ::DSpace
      end

      def self.class_year_field
        Metadata::Field.new('pu', 'date', 'classyear')
      end

      def self.embargo_date_field
        Metadata::Field.new('pu', 'embargo', 'lift')
      end

      def self.walk_in_access_field
        Metadata::Field.new('pu', 'mudd', 'walkin')
      end

      def self.department_field
        Metadata::Field.new('pu', 'department')
      end

      def self.certificate_program_field
        Metadata::Field.new('pu', 'certificate')
      end

      def self.title_field
        Metadata::Field.new('dc', 'title')
      end

      def initialize(results = [], parent = nil)
        @results = results
        @parent = parent
      end

      def find_items(metadata_field, value)
        if @results.empty?
          objs = self.class.kernel.findByMetadataValue(metadata_field.to_s, value, DConstants::ITEM)
          @results = objs.map do |obj|
            SeniorThesisItem.new(obj)
          end
        else
          selected_results = @results.select do |item|
            persisted_values = item.getMetadataByMetadataString(metadata_field.to_s).collect { |v| v.value }
            persisted_values.include?(value)
          end

          return self.class.new(selected_results, self)
        end

        self
      end

      def find_by_class_year(value)
        find_items(self.class.class_year_field.to_s, value)
      end

      def find_by_embargo_date(value)
        find_items(self.class.embargo_date_field.to_s, value)
      end

      def find_by_walk_in_access(value)
        find_items(self.class.walk_in_access_field.to_s, value)
      end

      def find_by_department(value)
        find_items(self.class.department_field.to_s, value)
      end

      def find_by_certificate_program(value)
        find_items(self.class.certificate_program_field.to_s, value)
      end

      def find_by_title(value)
        find_items(self.class.title_field.to_s, value)
      end

      def find_by_id(value)
        objs = []
        obj = Java::OrgDspaceContent::Item.find(self.class.kernel.context, value)
        objs << obj unless obj.nil?
        items = objs.map do |obj|
          SeniorThesisItem.new(obj)
        end

        if @results.empty?
          @results = items
        else
          return self.class.new(items, self)
        end

        self
      end
    end

    class SeniorThesisCommunity < ::DCommunity
      def self.kernel
        ::DSpace
      end

      def self.query_class
        SeniorThesisQuery
      end

      def self.class_year_field
                Metadata::Field.new('pu', 'date', 'classyear')
      end

      def self.embargo_date_field
        Metadata::Field.new('pu', 'embargo', 'lift')
      end

      def self.walk_in_access_field
        Metadata::Field.new('pu', 'mudd', 'walkin')
      end

      def initialize(obj)
        @obj = obj
      end

      def self.query
        query_class.new
      end

      def self.find_items(metadata_field, value)
        query = query_class.new
        query.find_items(metadata_field, value)
      end

      def self.find_by_class_year(value)
        find_items(class_year_field.to_s, value)
      end

      def self.find_by_embargo_date(value)
        find_items(embargo_date_field.to_s, value)
      end

      def self.find_by_walk_in_access(value)
        find_items(walk_in_access_field.to_s, value)

      end
    end
  end
end
