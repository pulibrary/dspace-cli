# frozen_string_literal: true

module DSpace
  module CLI
    module Jobs
      # Job for updating the handles for a set of DSpace Objects
      class BatchUpdateHandleJob < BatchUpdateJob
        def self.child_job_class
          UpdateHandleJob
        end

        def self.build_from_csv(file_path:, primary_column:)
          updates = CSVUpdate.build_from_file(path: file_path, primary_column: primary_column)
          build(updates)
        end
      end
    end
  end
end
