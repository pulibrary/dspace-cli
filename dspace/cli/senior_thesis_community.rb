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

    class SeniorThesisItem < ::DItem
      java_import org.dspace.workflow.WorkflowItem
      java_import org.dspace.content.Metadatum

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

      def self.build_metadata(schema, element, qualifier = nil, language = nil)
        metadata = Java::OrgDspaceContent::Metadatum.new
        metadata.schema = schema
        metadata.element = element
        metadata.qualifier = qualifier
        metadata.language = language
        metadata
      end

      def get_metadata
        @obj.getMetadata
      end

      def metadata
        list = Utils::ArrayList.new(get_metadata)
        list.to_a
      end

      def save
        @obj.save
        self.class.kernel.commit
        self
      end

      def add_metadata(schema, element, value, qualifier = nil, language = nil)
        metadata = self.class.build_metadata(schema, element, qualifier, language)
        metadata.value = value
        updated = get_metadata
        get_metadata.add(metadata)
        set_metadata(updated)
        metadata
      end

      class Java::OrgDspaceContent::DSpaceObject::MetadataCache
        attr_reader :metadata

        def initialize(metadata)
          @metadata = metadata
        end
      end

      class Java::OrgDspaceContent::Item
        field_accessor :metadataCache
        field_accessor :modifiedMetadata
      end

      def set_metadata(values)
        list = java.util.ArrayList.new(values)
        cache = Java::OrgDspaceContent::DSpaceObject::MetadataCache.new(list)
        @obj.metadataCache = cache
        @obj.modifiedMetadata = true
      end

      def self.metadata_match?(u, v)
        matches = false

        matches |= u.schema == v.schema
        matches |= u.element == v.element
        matches |= u.qualifier == v.qualifier
        matches |= u.language == v.language

        matches
      end

      def clear_metadata(schema, element, value, qualifier = nil, language = nil)
        cleared = self.class.build_metadata(schema, element, qualifier, language)
        current = metadata
        updated = []

        current.each do |metadatum|
          if !self.class.metadata_match?(metadatum, cleared)
            updated << metadatum
          end
        end

        set_metadata(updated)
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
