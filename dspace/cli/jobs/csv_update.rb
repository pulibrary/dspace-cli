
module DSpace
  module CLI
    module Jobs
      class CSVUpdate < FileUpdate
        def self.parse_csv(file_path)
          file = File.read(file_path, 'r:UTF-8')
          csv_table = CSV.parse(file.read, headers: true)
          file.close

          csv_table
        end

        def self.build_from_file(path:)
          csv_table = build_csv(path)

          updates = []

          rows = csv_table.to_a
          rows.each do |row|
            value = {}
            csv_table.headers.each do |column|
              column_index = csv_table.headers.find_index(column)
              cell = row[column_index]
              value[column] = cell
            end

            update = Update.new(value)
            updates << update
          end

          new(updates: updates)
        end

        def update_handles
          job = BatchUpdateHandleJob.build(self)
          job.perform
        end
      end
    end
  end
end
