module DSpace
  module CLI
    module Jobs
      class BatchJob < Job
        def initialize(child_jobs: [], **args)
          super(**args)
          @child_jobs = child_jobs
          @job_args = args
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
