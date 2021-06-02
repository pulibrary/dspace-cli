# frozen_string_literal: true

module DSpace
  module CLI
    module Jobs
      # Class abstracting the updates mapping file content (e. g. CSV or XML) to Item metadata fields
      class FileUpdate < BatchUpdate
        def self.file(file_path)
          File.new(file_path, 'r:UTF-8')
        end
      end
    end
  end
end
