module DSpace
  module CLI
    module Jobs
      class BatchUpdateHandleJob < BatchJob

        def self.child_job_class
          UpdateHandleJob
        end

        def self.build(updates)
          jobs = []

          updates.each do |update|
            jobs << child_job_class.new(**update.to_h)
          end

          new(child_jobs: jobs)
        end

        def self.build_from_csv(file_path:)
          updates = CSVUpdate.build_from_file(file_path: file_path)
          build(updates)
        end
      end
    end
  end
end
