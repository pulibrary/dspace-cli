# frozen_string_literal: true

module DSpace
  module CLI
    # Class Modeling the Java Class org.dspace.content.Bundle
    # @see https://github.com/DSpace/DSpace/blob/dspace-5.5/dspace-api/src/main/java/org/dspace/content/Bundle.java
    class Bundle < DSpaceObject
      def self.resource_type_id
        Core::Constants::BUNDLE
      end

      def self.model_class
        org.dspace.content.Bundle
      end

      def self.find(id)
        model = model_class.find(kernel.context, id)
        new(model)
      end

      def name
        @model.getName
      end

      def bitstreams
        bitstream_models = @model.getBitstreams
        bitstream_models.map { |bitstream_model| Bitstream.new(bitstream_model) }
      end

      def resource_policies
        policy_models_list = @model.getBundlePolicies
        policy_models = policy_models_list.to_a
        policy_models.map { |policy_model| ResourcePolicy.new(policy_model) }
      end

      def bitstream_resource_policies
        policy_models_list = @model.getBitstreamPolicies
        policy_models = policy_models_list.to_a
        policy_models.map { |policy_model| ResourcePolicy.new(policy_model) }
      end
    end
  end
end
