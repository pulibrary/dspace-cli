module DSpace
  module CLI
    class ExportJob
      def self.build_logger
        logger = Logger.new(STDOUT)
        logger.level = Logger::INFO
        logger
      end

      def initialize(obj)
        @obj = obj
        @logger = self.class.build_logger
      end

      def resource_id
        @obj.id
      end

      def resource_type
        @obj.type_text
      end

      def self.destination_path
        Pathname.new("#{__FILE__}/../../../exports")
      end

      def self.dspace_home_path
        Pathname.new('/dspace')
      end

      def self.dspace_bin_path
        Pathname.new("#{dspace_home_path}/bin/dspace")
      end

      def export_command
        "#{self.class.dspace_bin_path} export --type #{resource_type} --id #{resource_id} --number #{resource_id} --dest #{self.class.destination_path.realpath}"
      end

      def perform
        @logger.info("Exporting #{resource_id} to #{self.class.destination_path.realpath}...")
        if File.exist?("#{self.class.destination_path.realpath}/#{resource_id}")
          @logger.info("Directory #{self.class.destination_path.realpath}/#{resource_id} exists: might #{resource_id} have already been exported?")
        else
          raise "Failed to execute #{export_command}" unless system(export_command)
        end
      end
    end
  end
end
