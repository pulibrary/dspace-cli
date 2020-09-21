# frozen_string_literal: true

module DSpace
  module CLI
    class Item
      java_import org.dspace.workflow.WorkflowItem
      java_import org.dspace.content.Metadatum
      java_import org.dspace.content.MetadataField
      java_import org.dspace.content.MetadataSchema
      java_import org.dspace.handle.HandleManager
      java_import(org.dspace.content.InstallItem)

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
      # rubocop:disable Naming/MethodName
      def getMetadataByMetadataString(metadata_field)
        @obj.getMetadataByMetadataString(metadata_field)
      end
      # rubocop:enable Naming/MethodName

      def self.find(id)
        obj = Java::OrgDspaceContent::Item.find(kernel.context, id)
        return if obj.nil?

        new(obj)
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

      def update
        # This is likely where the duplication is occurring
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
        database_query = 'SELECT * FROM MetadataValue WHERE resource_id = ?'

        row_iterator = Java::OrgDspaceStorageRdbms::DatabaseManager.query(self.class.kernel.context, database_query, id.to_java)

        rows = []
        rows << row_iterator.next while row_iterator.hasNext
        rows
      end

      def find_metadata_objects
        values = metadata_database_rows.map do |row|
          metadata_field_id = row.getIntColumn('metadata_field_id')
          metadata_field = Java::OrgDspaceContent::MetadataField.find(self.class.kernel.context, metadata_field_id)

          schema_id = metadata_field.getSchemaID
          schema_model = Java::OrgDspaceContent::MetadataSchema.find(self.class.kernel.context, schema_id)

          schema = schema_model.getName
          element = metadata_field.getElement
          qualifier = metadata_field.getQualifier
          value = row.getStringColumn('text_value')
          language = row.getStringColumn('text_lang')

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
      module Java
        module OrgDspaceContent
          module DSpaceObject
            class MetadataCache
              attr_reader :metadata

              def initialize(metadata)
                @metadata = metadata
              end
            end
          end
        end
      end

      # I am not certain that this is needed
      module Java
        module OrgDspaceContent
          class Item
            field_accessor :metadataCache
            field_accessor :modifiedMetadata
          end
        end
      end

      # I am not certain that this is needed
      # rubocop:disable Naming/AccessorMethodName
      def set_metadata(values)
        list = java.util.ArrayList.new(values)
        cache = Java::OrgDspaceContent::DSpaceObject::MetadataCache.new(list)
        @obj.metadataCache = cache
        @obj.modifiedMetadata = true
      end
      # rubocop:enable Naming/AccessorMethodName

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
        MetadataField.new('dc', 'title')
      end

      def self.author_field
        MetadataField.new('dc', 'contributor', 'author')
      end

      def self.uri_field
        MetadataField.new('dc', 'identifier', 'uri')
      end

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

      def authors
        @obj.getMetadataByMetadataString(self.class.author_field.to_s).collect(&:value)
      end

      def author
        authors.first
      end

      def uris
        @obj.getMetadataByMetadataString(self.class.uri_field.to_s).collect(&:value)
      end

      def uri
        authors.first
      end

      def handle_uris
        uris.select { |uri| uri =~ /ark\:/ }
      end

      def submission_ids
        @obj.getMetadataByMetadataString(self.class.submission_id_field.to_s).collect(&:value)
      end

      def submission_id
        submission_ids.first
      end

      def submission_id=(value)
        clear_metadata('pu', 'submissionid')
        update
        add_metadata('pu', 'submissionid', value)
        update
        self.class.kernel.commit
      end

      def archive
        return if archived?

        Java::OrgDspaceContent::InstallItem.installItem(self.class.kernel.context, workflow_item.obj)
        self.class.kernel.commit
      end

      def persisted?
        !@obj.nil?
      end

      def self.workflow_item_class
        SeniorThesisWorkflowItem
      end

      def self.collection_class
        Collection
      end

      def workflow_item
        workflow_obj = Java::OrgDspaceWorkflow::WorkflowItem.findByItem(self.class.kernel.context, @obj)
        return if workflow_obj.nil?

        self.class.workflow_item_class.new(workflow_obj)
      end

      def add_task_pool_users(emails)
        return if workflow_item.nil?

        workflow_item.add_task_pool_users(emails)
        workflow_item.update
      end

      def add_task_pool_user(email)
        add_task_pool_users([email])
      end

      def remove_task_pool_users(emails)
        return if workflow_item.nil?

        workflow_item.remove_task_pool_users(emails)
        workflow_item.update
      end

      def remove_task_pool_user(email)
        remove_task_pool_users([email])
      end

      def collections
        @obj.getCollections.map { |collection_obj| self.class.collection_class.new(collection_obj) }
      end

      def self.find_collection_by_title(title)
        # This should be restructured
        query = collection_class.query
        query.find_collections_by_title(title)
        return if query.results.empty?

        query.results.first
      end

      def self.find_collection_by_handle(handle)
        obj = Java::OrgDspaceHandle::HandleManager.resolveToObject(kernel.context, handle)
        return if obj.nil?

        collection_class.new(obj)
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
        workflow_item&.delete
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

      def submitter=(eperson)
        @obj.setSubmitter(eperson)
      end

      def advance_workflow(eperson)
        return if workflow_item.nil?

        # This increases the state by 1 step
        Java::OrgDspaceWorkflow::WorkflowManager.advance(self.class.kernel.context, workflow_item.obj, eperson, true, true)
      end

      # This needs to be refactored
      def self.valid_workflow_state?(state)
        state > Java::OrgDspaceWorkflow::WorkflowManager::WFSTATE_ARCHIVE || state <= Java::OrgDspaceWorkflow::WorkflowManager::WFSTATE_STEP1
      end

      def advance_workflow_to_state(eperson, next_state)
        return self.state = next_state if next_state == Java::OrgDspaceWorkflow::WorkflowManager::WFSTATE_STEP1POOL

        return archive if next_state == Java::OrgDspaceWorkflow::WorkflowManager::WFSTATE_ARCHIVE

        return if workflow_item.nil? || self.class.valid_workflow_state?(next_state) || state == next_state

        self.state = next_state - 1
        update

        # This increases the state by 1 step
        Java::OrgDspaceWorkflow::WorkflowManager.advance(self.class.kernel.context, workflow_item.obj, eperson, true, true)
      end

      def export_job
        ExportJob.new(self)
      end

      def export
        export_job.perform
      end

      def move_collection(from, to, _inherit_default_policies = false)
        add_to_collection(to.handle)
        remove_from_collection(from.handle)
      end

      def move_collection_by_handles(from_handle, to_handle, _inherit_default_policies = false)
        add_to_collection(to_handle)
        remove_from_collection(from_handle)
      end
    end
  end
end
