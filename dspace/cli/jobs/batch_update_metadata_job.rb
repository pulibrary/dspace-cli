# frozen_string_literal: true

module DSpace
  module CLI
    module Jobs
      # Job for updating the metadata for a set of Items
      class BatchUpdateMetadataJob
        java_import org.dspace.eperson.EPerson

        def self.kernel
          ::DSpace
        end

        def self.build_logger
          logger = Logger.new($stdout)
          logger.level = Logger::INFO
          logger
        end

        def self.find_item_ids(primary_column, metadatum_value)
          metadata_field = MetadataField.build_from_column(primary_column)
          query = Query.find_items(metadata_field, metadatum_value)
          query.results.map(&:id)
        end

        def self.build_with_column_id(primary_column, update)
          values = update.to_h.dup
          metadata = values.except(:primary_column)

          metadatum_value = metadata.send(primary_column.to_sym)
          item_ids = find_item_ids(primary_column, metadatum_value)

          new(item_ids, metadata)
        end

        def self.build_from_csv(file_path:)
          update = CSVUpdate.build_from_file(path: file_path)
          build_with_column_id(update)
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
