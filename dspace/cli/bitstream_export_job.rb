module DSpace
  module CLI
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

      def self.destination_path
        Pathname.new("#{__FILE__}/../../../exports/bitstreams")
      end

      def output_file_path
        File.join(self.class.destination_path, bitstream_id)
      end

      def self.block_size
        4096
      end

      def perform
        output_bytes_class = Java::int[self.class.block_size]
        output_bytes = output_bytes_class.new
        input_stream = @bitstream.retrieve
        output_file = File.open(output_file_path, 'wb')
        @logger.info("Exporting #{bitstream_id} to #{output_file_path}...")

        while input_stream.read(output_bytes) > 0
          output_file << output_bytes
        end

        input_stream.close
        output_file.close
      end
    end
  end
end
