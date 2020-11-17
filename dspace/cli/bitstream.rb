# frozen_string_literal: true

module DSpace
  module CLI
    # Class Modeling the Java Class org.dspace.content.Bitstream
    # @see https://github.com/DSpace/DSpace/blob/dspace-5.5/dspace-api/src/main/java/org/dspace/content/Bitstream.java
    class Bitstream < DSpaceObject
      def self.resource_type_id
        Core::Constants::BITSTREAM
      end

      def self.model_class
        org.dspace.content.Bitstream
      end

      def self.find(id)
        model = model_class.find(kernel.context, id)
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

      def export_job
        CLI::Jobs::BitstreamExportJob.new(self)
      end

      def export
        export_job.perform
      end
    end
  end
end
