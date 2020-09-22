
module DSpace
  module CLI
    module Jobs

      class FileUpdate < BatchUpdate
        def self.file(file_path)
          File.new(file_path, 'r:UTF-8')
        end
      end

    end
  end
end
