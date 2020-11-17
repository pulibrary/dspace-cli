# frozen_string_literal: true

require 'logger'

module DSpace
  module CLI
    module Jobs
      # This implements an asynchronous, blocking job for exporting the content of Bitstreams
      class BitstreamExportJob
        def self.build_logger
          logger = Logger.new($stdout)
          logger.level = Logger::INFO
          logger
        end

        def initialize(bitstream)
          @bitstream = bitstream
          @logger = self.class.build_logger
        end

        def bitstream_id
          @bitstream.id
        end

        def resource_type
          @bitstream.type_text
        end

        # This should be configurable
        def self.destination_path
          Pathname.new("#{File.dirname(__FILE__)}/../../../exports/bitstreams")
        end

        def output_file_name
          return "#{bitstream_id}.bin" unless @bitstream.file_extension

          "#{bitstream_id}.#{@bitstream.file_extension}"
        end

        # This should include the file extension
        def output_file_path
          File.join(self.class.destination_path, output_file_name)
        end

        def self.block_size
          4096
        end

        def perform
          output_bytes_class = Java::byte[self.class.block_size]
          output_bytes = output_bytes_class.new
          input_stream = @bitstream.retrieve
          output_file = File.open(output_file_path, 'wb')
          @logger.info("Exporting #{bitstream_id} to #{output_file_path}...")

          output_file << output_bytes while input_stream.read(output_bytes).positive?

          input_stream.close
          output_file.close
        end
      end
    end
  end
end
