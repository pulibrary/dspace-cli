module DSpace
  module CLI
    module Jobs
      class BatchUpdateHandleJob < BatchImportJob

        def self.child_job_class
          UpdateHandleJob
        end

        def self.build_from_csv(file_path:)
          updates = CSVUpdate.build_from_file(path: file_path)
          build(updates)
        end
      end
    end
  end
end
