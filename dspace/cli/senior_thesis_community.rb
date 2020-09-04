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

      def id
        @obj.getID
      end

      def handle
        @obj.getHandle
      end

      # This needs to be abstracted
      def getMetadataByMetadataString(metadata_field)
        @obj.getMetadataByMetadataString(metadata_field)
      end

      def removeItem(item)
        @obj.removeItem(item.obj)
      end

      def addItem(item)
        @obj.addItem(item.obj)
      end

      def update
        @obj.update
        self.class.kernel.commit
      end
    end

    class SeniorThesisWorkflowItem
      java_import org.dspace.storage.rdbms.DatabaseManager
      java_import org.dspace.eperson.EPerson
      java_import org.dspace.workflow.WorkflowManager

      attr_reader :obj

      def self.kernel
        ::DSpace
      end

      # This is some internal bug; I am not certain why I cannot use this from DItem
      def initialize(obj)
        @obj = obj
      end

      def id
        @obj.getID
      end

      def update
        @obj.update
        self.class.kernel.commit
        self
      end

      def delete
        @obj.deleteWrapper
        self.class.kernel.commit
        @obj = nil
      end

      def state
        @obj.getState
      end

      def state=(value)
        @obj.setState(value)
      end

      def self.delete_query
        "DELETE FROM tasklistitem WHERE eperson_id = ? AND workflow_id = ?"
      end

      def self.delete_from_database(eperson_id, workflow_id)
        Java::OrgDspaceStorageRdbms::DatabaseManager.updateQuery(kernel.context, delete_query, eperson_id.to_java, workflow_id.to_java)
        kernel.commit
      end

      # magical task pool population
      def create_workflow_tasks(epeople)
        epeople.each do |eperson|
          table_row = Java::OrgDspaceStorageRdbms::DatabaseManager.row("tasklistitem")
          table_row.setColumn("eperson_id", eperson.getID)
          table_row.setColumn("workflow_id", id)
          Java::OrgDspaceStorageRdbms::DatabaseManager.insert(self.class.kernel.context, table_row)

          self.class.kernel.commit

          self.state = Java::OrgDspaceWorkflow::WorkflowManager::WFSTATE_STEP1POOL
          update
        end
      end

      def delete_workflow_tasks(epeople)
        epeople.each do |eperson|
          self.class.delete_from_database(eperson.getID, id)
        end
      end

      def remove_task_pool_users(emails)
        users = emails.map do |email|
          Java::OrgDspaceEperson::EPerson.findByEmail(self.class.kernel.context, email)
        end
        epeople = users.reject(&:nil?)

        delete_workflow_tasks(epeople)
      end

      def remove_task_pool_user(email)
        remove_task_pool_users([email])
      end

      def add_task_pool_users(emails)
        users = emails.map do |email|
          Java::OrgDspaceEperson::EPerson.findByEmail(self.class.kernel.context, email)
        end
        epeople = users.reject(&:nil?)

        create_workflow_tasks(epeople)
      end

      def add_task_pool_user(email)
        add_task_pool_users([email])
      end
    end

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

      # This cannot be used due to some issues between the splat operator and Java varargs
      def self.query_table(query, *params)
        Java::OrgDspaceStorageRdbms::DatabaseManager.query(kernel.context, query, *params)
      end

      def self.select_language_query
        "SELECT * FROM MetadataValue WHERE resource_id = ? AND metadata_field_id = ? AND text_value = ? AND text_lang = ?"
      end

      def self.select_value_query
        "SELECT * FROM MetadataValue WHERE resource_id = ? AND metadata_field_id = ? AND text_value = ?"
      end

      def self.update_language_query
        "UPDATE MetadataValue SET text_value = ?, text_lang = ? WHERE resource_id = ? AND metadata_field_id = ?"
      end

      def self.update_value_query
        "UPDATE MetadataValue SET text_value = ? WHERE resource_id = ? AND metadata_field_id = ?"
      end

      def self.insert_language_query
        "INSERT INTO MetadataValue (resource_id, resource_type_id, metadata_field_id, text_value, text_lang) VALUES (?, ?, ?, ?, ?)"
      end

      def self.insert_value_query
        "INSERT INTO MetadataValue (resource_id, resource_type_id, metadata_field_id, text_value) VALUES (?, ?, ?, ?)"
      end

      def self.delete_language_query
        "DELETE FROM MetadataValue WHERE resource_id = ? AND metadata_field_id = ? AND text_value = ? AND text_lang = ?"
      end

      def self.delete_value_query
        "DELETE FROM MetadataValue WHERE resource_id = ? AND metadata_field_id = ? AND text_value = ?"
      end

      def self.update_table(query, *params)
        Java::OrgDspaceStorageRdbms::DatabaseManager.updateQuery(kernel.context, query, *params)
      end

      def self.select_from_database(item_id, metadata_field_id, text_value, text_lang)
        lang = text_lang.nil? ? "" : text_lang

        if lang.empty?
          database_query = select_value_query
          Java::OrgDspaceStorageRdbms::DatabaseManager.query(kernel.context, database_query, item_id.to_java, metadata_field_id.to_java, text_value)
        else
          database_query = select_language_query
          Java::OrgDspaceStorageRdbms::DatabaseManager.query(kernel.context, database_query, item_id.to_java, metadata_field_id.to_java, text_value, lang)
        end

      end

      def self.update_in_database(text_value, text_lang, item_id, metadata_field_id)
        lang = text_lang.nil? ? "" : text_lang

        if lang.empty?
          database_query = update_value_query
          Java::OrgDspaceStorageRdbms::DatabaseManager.updateQuery(kernel.context, database_query, text_value, item_id.to_java, metadata_field_id.to_java)
        else
          database_query = update_language_query
          Java::OrgDspaceStorageRdbms::DatabaseManager.updateQuery(kernel.context, database_query, text_value, lang, item_id.to_java, metadata_field_id.to_java)
        end
      end

      def self.create_in_database(item_id, metadata_field_id, text_value, text_lang)
        lang = text_lang.nil? ? "" : text_lang

        if lang.empty?
          database_query = insert_value_query
          Java::OrgDspaceStorageRdbms::DatabaseManager.updateQuery(kernel.context, database_query, item_id.to_java, Java::OrgDspaceCore::Constants::ITEM, metadata_field_id.to_java, text_value)
        else
          database_query = insert_language_query
          Java::OrgDspaceStorageRdbms::DatabaseManager.updateQuery(kernel.context, database_query, item_id.to_java, Java::OrgDspaceCore::Constants::ITEM, metadata_field_id.to_java, text_value, lang)
        end
      end

      def self.delete_from_database(item_id, metadata_field_id, text_value, text_lang)
        lang = text_lang.nil? ? "" : text_lang

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
        while(row_iterator.hasNext)
          rows << row_iterator.next
        end

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
        metadata_field_id == metadatum.metadata_field_id
      end

      def ==(metadatum)
        matches = matches_field?(metadatum)

        matches &&= @text_value == metadatum.value
        # matches &&= @text_lang == metadatum.language

        text_lang_value = @text_lang.nil? ? "" : @text_lang
        compared_text_lang_value = metadatum.language.nil? ? "" : metadatum.language
        matches &&= text_lang_value == compared_text_lang_value

        matches
      end
    end

    class SeniorThesisItem < ::DItem
      java_import org.dspace.workflow.WorkflowItem
      java_import org.dspace.content.Metadatum
      java_import org.dspace.content.MetadataField
      java_import org.dspace.content.MetadataSchema
      java_import org.dspace.handle.HandleManager

      attr_reader :obj, :metadata

      def self.kernel
        ::DSpace
      end

      # This is some internal bug; I am not certain why I cannot use this from DItem
      def initialize(obj)
        @obj = obj
        @metadata = build_metadata
      end

      # This is some internal bug; I am not certain why I cannot use this from DItem
      def getMetadataByMetadataString(metadata_field)
        @obj.getMetadataByMetadataString(metadata_field)
      end

      def self.find_metadata_field(schema, element, qualifier = nil)
        schema_model = Java::OrgDspaceContent::MetadataSchema.find(kernel.context, schema)
        raise "Failed to find the MetadataSchema record for #{schema} (#{schema.class})" if schema_model.nil?

        # STDOUT.puts("Found the schema record with #{schema} #{schema.class}")
        # STDOUT.puts("Querying for the MetadataField record for #{schema}.#{element}.#{qualifier} (#{schema_model})")
        Java::OrgDspaceContent::MetadataField.findByElement(kernel.context, schema_model.getSchemaID, element, qualifier)
      end

      def build_metadatum(schema, element, qualifier = nil, language = nil)
        metadata_field = self.class.find_metadata_field(schema, element, qualifier)

        DSpace::CLI::Metadatum.build(self, metadata_field, element, qualifier, language)
      rescue => error
        STDERR.puts("Failed to find the MetadataField record for #{schema}.#{element}.#{qualifier}")
        STDERR.puts error.message
        STDERR.puts error.backtrace.join("\n")
        return
      end

      # I am not certain that this is needed
      def get_metadata
        values = @obj.getMetadata
        list = Utils::ArrayList.new(values)
        list.to_a
      end

      def update
        @metadata.each(&:update)
        @obj.update
        self.class.kernel.commit
        self
      end

      def add_metadata(schema, element, value, qualifier = nil, language = nil)
        new_metadatum = build_metadatum(schema, element, qualifier, language)
        return if new_metadatum.nil?

        new_metadatum.value = value
        @metadata << new_metadatum
        new_metadatum
      end

      def build_metadata
        # This does not disambiguate between the "dc" and "dcterms" schema
        # As a result, duplicate metadata are generated
        values = @obj.getMetadata
        list = Utils::ArrayList.new(values)
        current_objs = list.to_a

        built = []
        current_objs.each do |metadata_obj|
          new_metadatum = build_metadatum(metadata_obj.schema, metadata_obj.element, metadata_obj.qualifier, metadata_obj.language)
          next if new_metadatum.nil?

          new_metadatum.value = metadata_obj.value

          built << new_metadatum
        end
        @metadata = built
      end

      def remove_metadata(schema, element, value, qualifier = nil, language = nil)
        new_metadatum = build_metadatum(schema, element, qualifier, language)
        return if new_metadatum.nil?

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

      def remove_duplicated_metadata
        updated_metadata = []
        existing_metadata = metadata

        metadata.each do |metadatum|
          matching_metadata = existing_metadata.select { |md| md == metadatum }

          if matching_metadata.length > 1
            if updated_metadata.select { |md| md == metadatum }.empty?
              updated_metadata << metadatum
            else
              metadatum.delete
            end
          else
            updated_metadata << metadatum
          end
        end

        @metadata = updated_metadata
      end

      def remove_duplicated_metadata_field(schema, element, qualifier = nil, language = nil)
        new_metadatum = build_metadatum(schema, element, qualifier, language)
        return if new_metadatum.nil?
        new_metadatum.language = language

        updated_metadata = []
        metadata.each do |metadatum|
          if metadatum.matches_field?(new_metadatum)

            existing_metadata = metadata
            matching_metadata = existing_metadata.select { |md| md == metadatum }

            if matching_metadata.length > 1

              duplicate_metadata = matching_metadata.pop
              duplicate_metadata.delete

              # updated_metadata << metadata
            else
              updated_metadata << metadatum
            end

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
        new_metadatum = build_metadatum(schema, element, qualifier, language)
        return if new_metadatum.nil?

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

      def self.find_collection_by_title(title)
        # This should be restructured
        query = DSpace::CLI::SeniorThesisCommunity.query
        query.find_collections_by_title(title)
        return if query.results.empty?

        query.results.first
      end

      def self.find_collection_by_handle(handle)
        obj = Java::OrgDspaceHandle::HandleManager.resolveToObject(kernel.context, handle)
        return if obj.nil?

        SeniorThesisCollection.new(obj)
      end

      def add_to_collection(handle)
        collection = self.class.find_collection_by_handle(handle)
        return if collection.nil?

        collection.addItem(self)
        collection.update
      end

      def remove_from_collection(handle)
        collection = self.class.find_collection_by_handle(handle)
        return if collection.nil?

        collection.removeItem(self)
        collection.update
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
      java_import org.dspace.core.Constants

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

      def find_collections(metadata_field, value)
        if @results.empty?
          objs = self.class.kernel.findByMetadataValue(metadata_field.to_s, value, Java::OrgDspaceCore::Constants::COLLECTION)
          @results = objs.map do |obj|
            SeniorThesisCollection.new(obj)
          end
        else
          selected_results = @results.select do |collection|
            persisted_values = collection.getMetadataByMetadataString(metadata_field.to_s).collect { |v| v.value }
            persisted_values.include?(value)
          end

          return self.class.new(selected_results, self)
        end

        self
      end

      def find_items(metadata_field, value)
        if @results.empty?
          objs = self.class.kernel.findByMetadataValue(metadata_field.to_s, value, Java::OrgDspaceCore::Constants::ITEM)
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

      def find_collections_by_title(value)
        find_collections(self.class.title_field.to_s, value)
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
