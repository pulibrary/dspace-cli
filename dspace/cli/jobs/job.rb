# frozen_string_literal: true

require 'logger'

module DSpace
  module CLI
    module Jobs
      # Base Class modeling synchronous and asynchronous jobs
      class Job
        def self.build_logger(level)
          logger = Logger.new($stdout)
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
