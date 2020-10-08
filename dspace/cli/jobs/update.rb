require 'ostruct'

module DSpace
  module CLI
    module Jobs
      class Update < OpenStruct
        def update_handles_from_file(csv_file_path:)
          job = DSpace::CLI::Jobs::BatchUpdateHandleJob.build_from_csv(file_path: csv_file_path)
          job.perform
        end
      end
    end
  end
end
