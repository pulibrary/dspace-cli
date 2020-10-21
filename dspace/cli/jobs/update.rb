# frozen_string_literal: true

require 'ostruct'

module DSpace
  module CLI
    module Jobs
      # Base class modeling a set of changes being applied to a DSpace Object
      class Update < OpenStruct
        def update_handles_from_file(csv_file_path:)
          job = DSpace::CLI::Jobs::BatchUpdateHandleJob.build_from_csv(file_path: csv_file_path)
          job.perform
        end
      end
    end
  end
end
