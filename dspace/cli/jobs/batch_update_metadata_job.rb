module DSpace
  module CLI
    module Jobs
      class BatchUpdateMetadataJob
        java_import org.dspace.eperson.EPerson

        def self.kernel
          ::DSpace
        end

        def self.build_logger
          logger = Logger.new(STDOUT)
          logger.level = Logger::INFO
          logger
        end

        def initialize(item_ids, metadata)
          @item_ids = item_ids

          @metadata = metadata

          @logger = self.class.build_logger
        end

        def self.item_class
          Item
        end

        def items
          @item_ids.map do |item_id|
            self.class.item_class.find(item_id.to_i)
          end
        end

        def perform
          items.each do |item|
            metadata.each do |_metadatum|
              @logger.info("Updating the Item #{item.id} with the metadatum #{@metadata}...")

              item.add_metadata(
                schema: metadata.schema,
                element: metadata.element,
                qualifier: metadata.qualifier,
                value: metadata.value,
                language: metadata.language
              )
              item.update
            end
          end
        end
      end
    end
  end
end
