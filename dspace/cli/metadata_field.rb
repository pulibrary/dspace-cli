# frozen_string_literal: true

module DSpace
  module CLI
    class MetadataField
      attr_reader :schema, :element, :qualifier

      def self.kernel
        ::DSpace
      end

      def self.model_class
        Java::OrgDspaceContent::MetadataSchema
      end

      def self.find_schema_model(model:)
        schema_id = model.getSchemaID
        model_class.find(kernel.context, schema_id)
      end

      def self.build_from_column(primary_column)
        schema_name, element, qualifier = primary_column.split('.')
        schema_model = model_class.findByNamespace(kernel.context, schema_name)
        new(schema_name, element, qualifier, nil, schema_model)
      end

      def self.build(model:)
        schema_model = find_schema_model(model: model)
        element = model.getElement
        qualifier = model.getQualifier

        new(schema_model.getName, element, qualifier, model, schema_model)
      end

      def initialize(schema, element, qualifier = nil, model = nil, schema_model = nil)
        @schema = schema
        @element = element
        @qualifier = qualifier
        @model = model

        @schema_model = schema_model
      end

      def to_s
        if qualifier.nil?
          "#{schema}.#{element}"
        else
          "#{schema}.#{element}.#{qualifier}"
        end
      end

      def schema_id
        @schema_model.getSchemaID
      end
    end
  end
end
