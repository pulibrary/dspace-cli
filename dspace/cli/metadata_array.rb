# frozen_string_literal: true

module DSpace
  module CLI
    class MetadataArray
      attr_reader :elements

      def initialize(elements)
        @elements = elements
      end

      def select_by(schema:, element:, value: nil, qualifier: nil)
        field = MetadataField.new
        selected = select_by_field(field)
        return selected if value.nil?

        selected.select_by_value(value: value, qualifier: qualifier)
      end

      def select_by_field(field)
        if field.nil?
          new_elements = []
        else
        new_elements = @elements.select do |metadatum|
          metadatum.metadata_field == field
        end
        end

        self.class.new(new_elements)
      end

      def select_by_value(value:, qualifier: nil)
        if value.nil?
          new_elements = []
        else
        new_elements = @elements.select do |metadatum|
          if qualifier.nil?
            metadatum.value == value
          else
            metadatum.value == value && metadatum.qualifier == qualifier
          end
        end
        end

        self.class.new(new_elements)
      end

    end
  end
end
