# frozen_string_literal: true

module DSpace
  module CLI
    class Query
      java_import org.dspace.content.Item
      java_import org.dspace.core.Constants

      attr_reader :results, :parent

      def self.kernel
        ::DSpace
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

      def self.collection_class
        Collection
      end

      def find_collections(metadata_field, value)
        if @results.empty?
          objs = self.class.kernel.findByMetadataValue(metadata_field.to_s, value, Java::OrgDspaceCore::Constants::COLLECTION)
          @results = objs.map do |obj|
            self.class.collection_class.new(obj)
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
        if !@results.empty?
          selected_results = @results.map(&:members)

          return self.class.new(selected_results.flatten, self)
        end
      end

      def find_items(metadata_field, value)
        if @results.empty?
          objs = self.class.kernel.findByMetadataValue(metadata_field.to_s, value, Java::OrgDspaceCore::Constants::ITEM)
          @results = objs.map do |obj|
            self.class.item_class.new(obj)
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

      def find_by_author(value)
        find_items(self.class.author_field.to_s, value)
      end

      def self.community_class
        Community
      end

      def find_by_title(value)
        find_items(self.class.title_field.to_s, value)
      end

      def find_collections_by_title(value)
        find_collections(self.class.title_field.to_s, value)
      end

      
      def self.item_class
        DSpace::CLI::Item
      end

      def find_by_id(value)
        objs = []
        obj = Java::OrgDspaceContent::Item.find(self.class.kernel.context, value)
        objs << obj unless obj.nil?
        items = objs.map do |item_obj|
          self.class.item_class.new(item_obj)
        end

        return self.class.new(items, self) unless @results.empty?

        @results = items

        self
      end
    end
  end
end
