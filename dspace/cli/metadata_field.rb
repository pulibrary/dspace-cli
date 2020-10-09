# frozen_string_literal: true

module DSpace
  module CLI
    class MetadataField
      attr_reader :schema, :element, :qualifier

      def self.kernel
        ::DSpace
      end

      def self.find_schema_model(model:)
        schema_id = model.getSchemaID
        Java::OrgDspaceContent::MetadataSchema.find(kernel.context, schema_id)
      end

      def self.build_from_column(primary_column)
        schema, element, qualifier = primary_column.split('.')
        new(schema, element, qualifier)
      end

      def self.build(model:)
        schema_model = find_schema_model(model: model)
        element = model.getElement
        qualifier = model.getQualifier

        new(schema_model, element, qualifier, model)
      end

      def initialize(schema, element, qualifier = nil, model = nil)
        @schema = schema
        @element = element
        @qualifier = qualifier
        @model = model
      end

      def to_s
        if qualifier.nil?
          "#{schema}.#{element}"
        else
          "#{schema}.#{element}.#{qualifier}"
        end
      end

      def schema_id
        schema.getSchemaID
      end
    end
  end
end
