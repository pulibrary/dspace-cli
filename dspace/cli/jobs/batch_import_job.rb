module DSpace
  module CLI
    module Jobs
    class BatchImportJob < BatchJob

      def self.build(updates, **job_args)
        jobs = []

        updates.each do |update|
          jobs << child_job_class.new(**update.to_h)
        end

        new(child_jobs: jobs, **job_args)
      end

    end
  end
  end
end
