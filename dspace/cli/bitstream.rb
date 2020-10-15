# frozen_string_literal: true

module DSpace
  module CLI
    class Bitstream < DSpaceObject

      def self.resource_type_id
        Core::Constants::BITSTREAM
      end

      def self.model_class
        org.dspace.content.Bitstream
      end

      def self.find(id)
        model = model_class.find(self.kernel.context, id)
        new(model)
      end

      def name
        @model.getName
      end

      def bundles
        bundle_models = @model.getBundles
        bundle_models.map { |bundle_model| Bundle.new(bundle_model) }
      end

      def parent
        bundles.first
      end

      def resource_policies
        return [] if parent.nil?

        policies = parent.bitstream_resource_policies
        policies.select { |policy| policy.resource_type_id == self.class.resource_type_id && policy.resource_id == id }
      end
    end
  end
end

