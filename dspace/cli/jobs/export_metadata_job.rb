
module DSpace
  module CLI
    module Jobs
    class ExportMetadataJob

      def self.build_logger
        logger = Logger.new(STDOUT)
        logger.level = Logger::INFO
        logger
      end

      def initialize(dspace_object:, file_path:)
        @dspace_object = dspace_object
        @file_path = file_path
        @logger = self.class.build_logger
      end

      def self.default_headers
        [
          'id',
          'handle',
          'state'
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

        @dspace_object.metadata.each do |metadatum|
          row << metadatum.value
        end

        row
      end

      def existing_file
        @existing_file ||= File.new(@file_path, 'r:UTF-8')
      end

      def existing_csv_table
        return unless File.exist?(@file_path)

        existing_data = existing_file.read
        value = CSV.parse(existing_data, headers: true)
        # This raises an intermittent error - perhaps there is a race condition?
        # existing_file.close
        value
      end

      def existing_rows
        existing_csv_table.to_a
      end

      def existing_headers
        return [] if existing_csv_table.nil?

        existing_csv_table.headers
      end

      def csv_rows
        rows = existing_rows
        rows << headers if existing_headers.empty?

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
        @output_file ||= File.new(@file_path, 'w:UTF-8')
      end

      def write
        output_file.write(csv.to_s)
        output_file.close
      end

      def perform(**_args)
        @logger.info("Exporting the metadata to #{@file_path}...")
        write
      end
    end
  end
  end
end
