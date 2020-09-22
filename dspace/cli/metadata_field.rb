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

      def self.build(model:)
        schema_model = find_schema_model(model: model)
        schema = schema_model.getName
        element = model.getElement
        qualifier = model.getQualifier

        new(schema, element, qualifier, model)
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
    end
  end
end
