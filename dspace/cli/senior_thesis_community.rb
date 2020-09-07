require 'csv'
require 'pathname'

module DSpace
  module CLI
    class SeniorThesisCollection
      java_import org.dspace.storage.rdbms.DatabaseManager
      java_import org.dspace.handle.HandleManager
      attr_reader :obj

      def self.kernel
        ::DSpace
      end

      # This needs to be restructured to parse a configuration file
      def self.department_to_collection_map
        {
          'Comparative Literature' => '88435/dsp01rf55z7763',
          'English' => '88435/dsp01qf85nb35s'
        }
      end

      def self.find_for_department(department)
        return unless department_to_collection_map.key?(department)

        handle = department_to_collection_map[department]
        obj = Java::OrgDspaceHandle::HandleManager.resolveToObject(kernel.context, handle)
        return if obj.nil?

        self.new(obj)
      end

      def self.title_field
        Metadata::Field.new('dc', 'title')
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

      def titles
        @obj.getMetadataByMetadataString(self.class.title_field.to_s).collect { |v| v.value }
      end

      def title
        titles.first
      end

      def removeItem(item)
        database_statement = "DELETE FROM collection2item WHERE collection_id= ? AND item_id= ?"
        Java::OrgDspaceStorageRdbms::DatabaseManager.updateQuery(self.class.kernel.context, database_statement, id, item.id)
        self.class.kernel.commit
      end

      def remove_item(item)
        removeItem(item)
      end

      def addItem(item)
        @obj.addItem(item.obj)
      end

      def add_item(item)
        addItem(item)
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
      java_import org.dspace.handle.HandleManager

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

    require 'logger'
    class ExportJob
      def self.build_logger
        logger = Logger.new(STDOUT)
        logger.level = Logger::INFO
        logger
      end

      def initialize(obj)
        @obj = obj
        @logger = self.class.build_logger
      end

      def resource_id
        @obj.id
      end

      def resource_type
        @obj.type_text
      end

      def self.destination_path
        Pathname.new("#{__FILE__}/../../../exports")
      end

      def self.dspace_home_path
        Pathname.new('/dspace')
      end

      def self.dspace_bin_path
        Pathname.new("#{dspace_home_path}/bin/dspace")
      end

      def export_command
        "#{self.class.dspace_bin_path} export --type #{resource_type} --id #{resource_id} --number #{resource_id} --dest #{self.class.destination_path.realpath}"
      end

      def perform
        @logger.info("Exporting #{resource_id} to #{self.class.destination_path.realpath}...")
        if File.exists?("#{self.class.destination_path.realpath}/#{resource_id}")
          @logger.info("Directory #{self.class.destination_path.realpath}/#{resource_id} exists: might #{resource_id} have already been exported?")
        else
          raise "Failed to execute #{export_command}" unless system(export_command)
        end
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

      def self.find(id)
        obj = Java::OrgDspaceContent::Item.find(kernel.context, id)
        return if obj.nil?

        self.new(obj)
      end

      def self.find_metadata_field(schema, element, qualifier = nil)
        schema_model = Java::OrgDspaceContent::MetadataSchema.find(kernel.context, schema)
        raise "Failed to find the MetadataSchema record for #{schema} (#{schema.class})" if schema_model.nil?

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

      def update
        @metadata.each(&:update)
        @obj.update
        self.class.kernel.commit
        build_metadata
        self
      end

      def add_metadata(schema, element, value, qualifier = nil, language = nil)
        new_metadatum = build_metadatum(schema, element, qualifier, language)
        return if new_metadatum.nil?

        new_metadatum.value = value
        @metadata << new_metadatum
        new_metadatum
      end

      def metadata_database_rows
        database_query = "SELECT * FROM MetadataValue WHERE resource_id = ?"

        row_iterator = Java::OrgDspaceStorageRdbms::DatabaseManager.query(self.class.kernel.context, database_query, id.to_java)

        rows = []
        while(row_iterator.hasNext)
          rows << row_iterator.next
        end
        rows
      end

      def find_metadata_objects
        values = metadata_database_rows.map do |row|
          metadata_field_id = row.getIntColumn("metadata_field_id")
          metadata_field = Java::OrgDspaceContent::MetadataField.find(self.class.kernel.context, metadata_field_id)

          schema_id = metadata_field.getSchemaID
          schema_model = Java::OrgDspaceContent::MetadataSchema.find(self.class.kernel.context, schema_id)

          schema = schema_model.getName
          element = metadata_field.getElement
          qualifier = metadata_field.getQualifier
          value = row.getStringColumn("text_value")
          language = row.getStringColumn("text_lang")

          new_metadatum = build_metadatum(schema, element, qualifier, language)

          new_metadatum.value = value unless new_metadatum.nil?
          new_metadatum
        end

        values.reject(&:nil?)
      end

      def build_metadata
        @metadata = find_metadata_objects
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

      def type_text
        @obj.getTypeText
      end

      def self.title_field
        Metadata::Field.new('dc', 'title')
      end

      def self.department_field
        Metadata::Field.new('pu', 'department')
      end

      def self.certificate_program_field
        Metadata::Field.new('pu', 'certificate')
      end

      def self.class_year_field
        Metadata::Field.new('pu', 'date', 'classyear')
      end

      def titles
        @obj.getMetadataByMetadataString(self.class.title_field.to_s).collect { |v| v.value }
      end

      def title
        titles.first
      end

      def departments
        @obj.getMetadataByMetadataString(self.class.department_field.to_s).collect { |v| v.value }
      end

      def department
        departments.first
      end

      def certificate_programs
        @obj.getMetadataByMetadataString(self.class.certificate_program_field.to_s).collect { |v| v.value }
      end

      def certificate_program
        certificate_programs.first
      end

      def class_years
        @obj.getMetadataByMetadataString(self.class.class_year_field.to_s).collect { |v| v.value }
      end

      def class_year
        class_years.first
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

      def find_collections_for_departments
        collections = []
        departments.each do |department|
          # collection = self.class.find_collection_by_title(department)
          collection = SeniorThesisCollection.find_for_department(department)
          collections << collection unless collection.nil?
        end
        collections
      end

      def find_collections_for_certificate_programs
        collections = []
        certificate_programs.each do |program|
          collection = self.class.find_collection_by_title(program)
          collections << collection unless collection.nil?
        end
        collections
      end

      def add_to_collection(handle)
        collection = self.class.find_collection_by_handle(handle)
        return if collection.nil?

        collection.add_item(self)
        collection.update
      end

      def remove_from_collection(handle)
        collection = self.class.find_collection_by_handle(handle)
        return if collection.nil?

        collection.remove_item(self)
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

      def state
        return if workflow_item.nil?

        workflow_item.state
      end

      def state=(value)
        return if workflow_item.nil?

        workflow_item.state = value
        workflow_item.update
      end

      def archived?
        state.nil?
      end

      def submitter
        @obj.getSubmitter
      end

      def advance_workflow(eperson)
        return if workflow_item.nil? || archived?

        # This increases the state by 1 step
        WorkflowManager.advance(self.class.kernel.context, workflow_item, eperson, true, true)
      end

      def advance_workflow_to_state(eperson, next_state)
        if next_state == 5
          return self.state = next_state
        end
        return if workflow_item.nil? || next_state > 8 || next_state <= 5 || self.state == next_state

        self.state = next_state - 1

        # This increases the state by 1 step
        WorkflowManager.advance(self.class.kernel.context, workflow_item, eperson, true, true)
      end

      def export_job
        ExportJob.new(self)
      end

      def export
        export_job.perform
      end

      def move_collection(from, to, inherit_default_policies = false)
        add_to_collection(to.handle)
        remove_from_collection(from.handle)
      end

      def move_collection_by_handles(from_handle, to_handle, inherit_default_policies = false)
        add_to_collection(to_handle)
        remove_from_collection(from_handle)
      end
    end

    class SeniorThesisCommunity < ::DCommunity
      # This needs to be restructured to parse from a configuration file
      def self.certificate_program_titles
        [
          'Creative Writing Program'
        ]
      end

      # This needs to be restructured to parse from a configuration file
      def self.collection_titles
        [
          'African American Studies',
          'Anthropology',
          'Architecture School',
          'Art and Archaeology',
          'Astrophysical Sciences',
          'Chemical and Biological Engineering',
          'Chemistry',
          'Civil and Environmental Engineering',
          'Classics',
          'Comparative Literature',
          'Computer Science',
          'East Asian Studies',
          'Ecology and Evolutionary Biology',
          'Economics',
          'Electrical Engineering',
          'English',
          'French and Italian',
          'Geosciences',
          'German',
          'History',
          'Independent Concentration',
          'Mathematics',
          'Mechanical and Aerospace Engineering',
          'Molecular Biology',
          'Near Eastern Studies',
          'Neuroscience',
          'Operations Research and Financial Engineering',
          'Philosophy',
          'Physics',
          'Politics',
          'Woodrow Wilson School',
          'Psychology',
          'Slavic Languages and Literature',
          'Sociology',
          'Spanish and Portuguese'
        ]
      end

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

      def self.export_departments(year)
        collection_titles.each do |department_title|
          year_query = query.find_by_class_year(year)
          dept_query = year_query.find_by_department(department_title)
          dept_query.results.each do |item|
            item.export
          end
        end
      end

      def self.write_item_state_reports(year)
        collection_titles.each do |department_title|
          year_query = query.find_by_class_year(year)
          dept_query = year_query.find_by_department(department_title)
          report_name = "#{DSpace::CLI::ResultSet.normalize_department_title(department_title)}.csv"
          report = dept_query.result_set.item_state_report(report_name)
          report.write
        end

        certificate_program_titles.each do |program_title|
          year_query = query.find_by_class_year(year)
          program_query = year_query.find_by_certificate_program(program_title)
          report_name = "#{DSpace::CLI::ResultSet.normalize_department_title(program_title)}.csv"
          report = program_query.result_set.item_state_report(report_name)
          report.write
        end

      end

    end

    class Report

    end

    class ItemReport

    end

    class ItemStateReport
      attr_reader :items

      def initialize(items, output_file_path)
        @items = items
        @output_file_path = output_file_path
      end

      def self.root_path
        Pathname.new("#{File.dirname(__FILE__)}/../../reports")
      end

      def self.headers
        [
          'item',
          'title',
          'classyear',
          'state',
          'eperson'
        ]
      end

      def generate
        @output = CSV.generate do |csv|
          csv << self.class.headers

          items.each do |item|
            item_state = if item.state.nil?
                           'ARCHIVED' # This is a placeholder for the ARCHIVED status
                         else
                           item.state
                         end

            submitter = item.submitter
            row = [item.id, item.title, item.class_year, item_state, submitter.email]
            csv << row
          end
        end
      end

      def write
        generate if @output.nil?

        file = File.open(@output_file_path, 'wb:UTF-8')
        file.write(@output)
        file.close
      end
    end

    class ResultSet
      java_import(org.dspace.content.Collection)

      attr_reader :members

      def self.kernel
        ::DSpace
      end

      def initialize(members)
        @members = members
      end

      def add_to_collection(handle)
        obj = Java::OrgDspaceHandle::HandleManager.resolveToObject(self.class.kernel.context, handle)
        return if obj.nil?

        collection = SeniorThesisCollection.new(obj)

        members.each do |member|
          collection.addItem(member)
        end
        collection.update
      end

      def remove_from_collection(handle)
        obj = Java::OrgDspaceHandle::HandleManager.resolveToObject(self.class.kernel.context, handle)
        return if obj.nil?

        collection = SeniorThesisCollection.new(obj)

        members.each do |member|
          collection.removeItem(member)
        end
        collection.update
      end

      def add_task_pool_user(email)
        members.each do |member|
          member.workflow_item.add_task_pool_user(email)
          self.class.kernel.commit
        end
      end

      def move_collection(from_handle, to_handle, inherit_default_policies = false)
        members.each do |member|
          member.move_collection_by_handles(from_handle, to_handle, inherit_default_policies)
          self.class.kernel.commit
        end
      end

      def self.normalize_department_title(title)
        normal_title = title.downcase
        normal_title.gsub(/\s/, '_')
      end

      def item_state_report(output_file_name)
        output_file_path = File.join(ItemStateReport.root_path, output_file_name)

        ItemStateReport.new(members, output_file_path)
      end
    end

    require 'logger'

    class BatchJob

    end

    class BatchUpdateStateJob
      java_import org.dspace.eperson.EPerson

      def self.kernel
        ::DSpace
      end

      def self.build_logger
        logger = Logger.new(STDOUT)
        logger.level = Logger::INFO
        logger
      end

      def initialize(item_ids, state, eperson_email)
        @item_ids = item_ids
        @state = if state == 'ARCHIVED'
                   8 # This is a hack for the Item#advance_workflow method
                 else
                   state.to_i
                 end
        @eperson_email = eperson_email
        @logger = self.class.build_logger
      end

      def items
        @item_ids.map do |item_id|
          SeniorThesisItem.find(item_id.to_i)
        end
      end

      def eperson
        Java::OrgDspaceEperson::EPerson.findByEmail(self.class.kernel.context, @eperson_email)
      end

      def perform
        items.each do |item|
          @logger.info("Advancing Item #{item.id} to the state #{@state} for the user #{eperson.getEmail}...")
          item.advance_workflow_to_state(eperson, @state)
          item.update
        end
      end
    end

    class BatchUpdateJob < BatchJob
      attr_reader :jobs

      def self.build_logger
        logger = Logger.new(STDOUT)
        logger.level = Logger::INFO
        logger
      end

      def initialize(csv_file_path)
        @csv_file_path = csv_file_path
        @jobs = []
        @logger = self.class.build_logger
      end

      def csv_file
        @csv_file ||= File.open(@csv_file_path, 'rb:UTF-8')
      end

      def csv
        @csv ||= CSV.new(csv_file, headers: :first_row)
      end

      def table
        @table ||= csv.read
      end

      def rows
        table.to_a[1..-1]
      end

      def headers
        csv.headers
      end

      def find_column_index(column)
        value = headers.index(column)
        raise "Could not find the '#{column}' column" if value.nil?
        value
      end

      # This is not used for cross-DSpace batch updates
      def item_id_column
        find_column_index('item')
      end

      def title_column
        find_column_index('title')
      end

      def class_year_column
        find_column_index('classyear')
      end

      def state_column
        find_column_index('state')
      end

      def eperson_email_column
        find_column_index('eperson')
      end

      def self.update_state_job_class
        BatchUpdateStateJob
      end

      def batch_update_state_args
        batch_args = {}

        rows.each do |row|
          title = row[title_column]
          class_year = row[class_year_column]

          query = DSpace::CLI::SeniorThesisCommunity.find_by_class_year(class_year)
          sub_query = query.find_by_title(title)
          raise "Failed to find the Item for '#{title}' (graduating year #{class_year})" if sub_query.results.empty?

          item = sub_query.results.first
          item_id = item.id
          state = row[state_column]
          eperson_email = row[eperson_email_column]

          if batch_args.key?(eperson_email)

            job_args = batch_args[eperson_email]
            if job_args.key?(state)
              job_args[state] << item_id
            else
              job_args[state] = [item_id]
            end
          else
            job_args = {}
            batch_args[eperson_email] = job_args
          end
        end

        batch_args
      end

      def build_update_state_jobs
        jobs = []

        batch_update_state_args.each_pair do |eperson_email, job_args|
          job_args.each_pair do |state, item_ids|
            job = self.class.update_state_job_class.new(item_ids, state, eperson_email)
            jobs << job
          end
        end
        @jobs = jobs
      end

      def perform
        jobs.each { |job| job.perform }
      end

      def perform_update_state_jobs
        build_update_state_jobs
        perform
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

      def self.author_field
        Metadata::Field.new('dc', 'contributor', 'author')
      end

      def initialize(results = [], parent = nil)
        @results = results
        @parent = parent
      end

      def result_set
        ResultSet.new(@results)
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

      def find_by_author(value)
        find_items(self.class.author_field.to_s, value)
      end

      def self.community_class
        SeniorThesisCommunity
      end

      community_class.collection_titles.each do |title|
        normal_title = title.downcase
        normal_title = normal_title.gsub(/\s/, '_')
        method_name = "find_#{normal_title}_department_items"
        define_method(method_name.to_sym) do
          find_by_department(title)
        end
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
  end
end
