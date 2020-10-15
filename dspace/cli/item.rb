# frozen_string_literal: true

module DSpace
  module CLI
    class Item < DSpaceObject
      java_import org.dspace.core.Constants
      java_import org.dspace.workflow.WorkflowItem
      java_import org.dspace.content.Metadatum
      java_import org.dspace.content.MetadataField
      java_import org.dspace.content.MetadataSchema
      java_import org.dspace.handle.HandleManager
      java_import(org.dspace.content.InstallItem)
      java_import(org.dspace.discovery.IndexingService)

      attr_reader :metadata

      def initialize(obj)
        super(obj)
        @metadata = build_metadata
      end

      def self.find(id)
        obj = Java::OrgDspaceContent::Item.find(kernel.context, id)
        return if obj.nil?

        new(obj)
      end

      def update
        @metadata.each(&:update)
        @obj.update
        self.class.kernel.commit
        build_metadata
        self
      end

      def add_metadata(schema:, element:, value:, qualifier: nil, language: nil)
        new_metadatum = build_metadatum(schema, element, qualifier, language)
        return if new_metadatum.nil?

        new_metadatum.value = value
        @metadata << new_metadatum
        new_metadatum
      end

      def self.resource_type_id
        Java::OrgDspaceCore::Constants::ITEM
      end

      def self.select_all_metadata_value_query
        <<-SQL
          SELECT * FROM metadatavalue
            WHERE resource_id = ?
            AND resource_type_id = #{resource_type_id}
        SQL
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

      def self.author_field
        metadata_field_class.new('dc', 'contributor', 'author')
      end

      def self.uri_field
        metadata_field_class.new('dc', 'identifier', 'uri')
      end

      def self.date_accessioned_field
        metadata_field_class.new('dc', 'date', 'accessioned')
      end

      def self.date_issued_field
        metadata_field_class.new('dc', 'date', 'issued')
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
        uris.first
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

      def accession_dates
        @obj.getMetadataByMetadataString(self.class.date_accessioned_field.to_s).collect(&:value)
      end

      def date_accessioned
        accession_dates.first
      end

      def issued_dates
        @obj.getMetadataByMetadataString(self.class.date_issued_field.to_s).collect(&:value)
      end

      def date_issued
        issued_dates.first
      end

      def archive
        return if archived?

        Java::OrgDspaceContent::InstallItem.installItem(self.class.kernel.context, workflow_item.obj)
        self.class.kernel.commit
      end

      def self.workflow_item_class
        DSpace::CLI::WorkflowItem
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

      def valid_workflow_state?(workflow_state)
        valid_state = workflow_state >= self.class.pending_curator_review_state
        valid_state |= workflow_state <= self.class.archived_state
        valid_state |= !workflow_item.nil?
        valid_state |= state != workflow_state
        valid_state
      end

      def self.workflow_manager
        Java::OrgDspaceWorkflow::WorkflowManager
      end

      def advance_workflow(next_state, eperson)
        self.state = next_state - 1

        # This increases the state by 1 step
        self.class.workflow_manager.advance(self.class.kernel.context, workflow_item.obj, eperson, true, true)
      end

      def set_workflow(new_state:, eperson:)
        return archive if new_state == self.class.archived_state

        return unless valid_workflow_state?(new_state)

        # This is currently broken
        # advance_workflow(state, eperson)
        workflow_item.owner = eperson
        self.state = new_state
      end

      def set_workflow_with_submitter(new_state:)
        set_workflow(new_state: new_state, eperson: submitter)
      end

      def self.archived_state
        Java::OrgDspaceWorkflow::WorkflowManager::WFSTATE_ARCHIVE
      end

      def self.pending_curator_review_state
        Java::OrgDspaceWorkflow::WorkflowManager::WFSTATE_STEP1POOL
      end

      def self.under_curator_review_state
        Java::OrgDspaceWorkflow::WorkflowManager::WFSTATE_STEP1
      end

      def self.pending_admin_review_state
        Java::OrgDspaceWorkflow::WorkflowManager::WFSTATE_STEP2POOL
      end

      def self.under_admin_review_state
        Java::OrgDspaceWorkflow::WorkflowManager::WFSTATE_STEP2
      end

      def self.pending_editorial_review_state
        Java::OrgDspaceWorkflow::WorkflowManager::WFSTATE_STEP3POOL
      end

      def self.under_editorial_review_state
        Java::OrgDspaceWorkflow::WorkflowManager::WFSTATE_STEP3
      end

      def self.workflow_state_methods
        %i[
          archived_state
          pending_curator_review_state
          under_curator_review_state
          pending_admin_review_state
          under_admin_review_state
          pending_editorial_review_state
          under_editorial_review_state
        ]
      end

      workflow_state_methods.each do |method_name|
        segment = method_name.to_s.gsub('_state', '')
        state = send(method_name)

        base_method_name = "set_workflow_to_#{segment}"
        define_method(base_method_name.to_sym) do |eperson|
          set_workflow(new_state: state, eperson: eperson)
        end

        with_submitter_method_name = "set_workflow_to_#{segment}_with_submitter"
        define_method(with_submitter_method_name.to_sym) do
          set_workflow_with_submitter(new_state: state)
        end
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

      def bundles
        bundle_models = @model.getBundles
        bundle_models.map { |bundle_model| Bundle.new(bundle_model) }
      end
    end
  end
end
