# frozen_string_literal: true

module DSpace
  module CLI
    # Class modeling database queries targeting Senior Thesis Items
    class SeniorThesisQuery
      java_import org.dspace.content.Item
      java_import org.dspace.core.Constants

      attr_reader :results, :parent

      def self.kernel
        ::DSpace
      end

      def self.class_year_field
        MetadataField.new('pu', 'date', 'classyear')
      end

      def self.embargo_date_field
        MetadataField.new('pu', 'embargo', 'lift')
      end

      def self.walk_in_access_field
        MetadataField.new('pu', 'mudd', 'walkin')
      end

      def self.department_field
        MetadataField.new('pu', 'department')
      end

      def self.certificate_program_field
        MetadataField.new('pu', 'certificate')
      end

      def self.title_field
        MetadataField.new('dc', 'title')
      end

      def self.author_field
        MetadataField.new('dc', 'contributor', 'author')
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
            persisted_values = collection.getMetadataByMetadataString(metadata_field.to_s).collect(&:value)
            persisted_values.include?(value)
          end

          return self.class.new(selected_results, self)
        end

        self
      end

      def find_children
        return if @results.empty?

        selected_results = @results.map do |dspace_object|
          if dspace_object.respond_to?(:members)
            dspace_object.members
          else
            []
          end
        end

        self.class.new(selected_results.flatten, self)
      end

      def find_items(metadata_field, value)
        if @results.empty?
          found_objs = self.class.kernel.findByMetadataValue(metadata_field.to_s, value, Java::OrgDspaceCore::Constants::ITEM)

          # Filter for nil objects
          objs = found_objs.reject(&:nil?)

          @results = objs.map do |obj|
            SeniorThesisItem.new(obj)
          end
        else
          selected_results = @results.select do |item|
            persisted_values = item.getMetadataByMetadataString(metadata_field.to_s).collect(&:value)
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
        items = objs.map do |item_obj|
          SeniorThesisItem.new(item_obj)
        end

        return self.class.new(items, self) unless @results.empty?

        @results = items

        self
      end
    end
  end
end
