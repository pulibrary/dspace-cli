module DSpace
  module CLI
    module Jobs
    class BatchJob

      def self.build_logger
        logger = Logger.new(STDOUT)
        logger.level = Logger::INFO
        logger
      end

      # This should be moved to BatchUpdateJob
      def self.build(updates, **job_args)
        jobs = []

        updates.each do |update|
          jobs << child_job_class.new(**update.to_h)
        end

        new(child_jobs: jobs, **job_args)
      end

      def initialize(child_jobs: [], **job_args)
        @child_jobs = child_jobs
        @job_args = job_args
      end

      def perform
        @child_jobs.map do |job|
          job.perform(**@job_args)
        end
      end
    end
  end
  end
end
