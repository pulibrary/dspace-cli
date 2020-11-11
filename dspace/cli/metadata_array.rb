# frozen_string_literal: true

module DSpace
  module CLI
    class MetadataArray
      attr_reader :elements

      def self.kernel
        ::DSpace
      end

      def initialize(elements)
        @elements = elements
      end

      def select_by(schema:, element:, value: nil, language: nil)
        field = MetadataField.new
        selected = select_by_field(field)
        return selected if value.nil?

        selected.select_by_value(value: value, language: language)
      end

      def select_by_field(field)
        new_elements = if field.nil?
                         []
                       else
                         @elements.select do |metadatum|
                           metadatum.metadata_field == field
                         end
                       end

        self.class.new(new_elements)
      end

      def select_by_value(value:, language: nil)
        new_elements = if value.nil?
                         []
                       else
                         @elements.select do |metadatum|
                           if language.nil?
                             metadatum.value == value
                           else
                             metadatum.value == value && metadatum.language == language
                           end
                         end
                       end

        self.class.new(new_elements)
      end

      def select_by_element(element)
        subset = select_by_field(element.field)
        subset.select_by_value(value: element.value, language: element.language)
      end

      def uniq
        new_elements = elements.uniq { |e| [e.schema, e.element, e.qualifier, e.value, e.language] }

        self.class.new(new_elements)
      end

      def duplicate_elements
        new_elements = []

        elements.each do |element|
          subset = select_by_element(element)
          new_elements += subset.elements[1..-1] unless subset.elements.length > 1
        end

        self.class.new(new_elements)
      end

      def create
        elements.map(&:create)
      end

      def delete_all
        elements.map(&:delete_all_models)
      end

      def update
        delete_all
        create
      end
    end
  end
end
