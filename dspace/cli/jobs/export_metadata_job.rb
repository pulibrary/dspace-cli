# frozen_string_literal: true

module DSpace
  module CLI
    module Jobs
      # Job for exporting metadata from a DSpace Object
      class ExportMetadataJob
        def self.build_logger
          logger = Logger.new($stdout)
          logger.level = Logger::INFO
          logger
        end

        def initialize(dspace_object:, file_path:)
          @dspace_object = dspace_object
          @file_path = file_path
          @logger = self.class.build_logger
        end

        def self.default_headers
          %w[
            id
            handle
            state
            title
            author
            collection
          ]
        end

        def metadata_fields
          values = @dspace_object.metadata.map(&:metadata_field)
          values.uniq(&:to_s)
        end

        def headers
          values = self.class.default_headers

          metadata_fields.each do |metadata_field|
            values << metadata_field.to_s
          end

          values
        end

        def csv_row
          row = []
          row << @dspace_object.id
          row << @dspace_object.handle
          row << @dspace_object.state

          metadata_values = {}
          @dspace_object.metadata.each do |metadatum|
            key = metadatum.metadata_field.to_s
            metadata_value = metadata_values.fetch(key, [])

            metadata_value << metadatum.value.gsub(/\R/, '')

            metadata_values[key] = metadata_value
          end

          metadata_values.each_value do |value|
            row << value.join(';')
          end

          row
        end

        def build_existing_file
          File.new(@file_path, 'r:UTF-8')
        end

        def existing_csv_table
          return if File.empty?(@file_path)

          existing_file = build_existing_file
          CSV.parse(existing_file, headers: true)
        end

        def existing_rows
          existing_csv_table.to_a
        end

        def existing_headers
          return [] if existing_csv_table.nil?

          existing_csv_table.headers
        end

        def csv_rows
          rows = []
          rows << headers if File.empty?(@file_path)

          rows << csv_row
          rows
        end

        def build_csv
          CSV.generate do |csv|
            csv_rows.each do |row|
              csv << row
            end
          end
        end

        def csv
          @csv ||= build_csv
        end

        def output_file
          @output_file ||= File.new(@file_path, 'a:UTF-8')
        end

        def write
          output_file.write(csv.to_s)
          output_file.close
        end

        def perform(**_args)
          @logger.info("Exporting the metadata from #{@dspace_object.id} to #{@file_path}...")
          write
        end
      end
    end
  end
end
