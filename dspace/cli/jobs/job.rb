require 'logger'

module DSpace
  module CLI
    module Jobs
      class Job
        def self.build_logger(level)
          logger = Logger.new(STDOUT)
          logger.level = level
          logger
        end

        def initialize(**args)
          log_level = args.fetch(:log_level, Logger::INFO)
          @logger = self.class.build_logger(log_level)
        end

        def self.item_class
          Item
        end
      end
    end
  end
end
