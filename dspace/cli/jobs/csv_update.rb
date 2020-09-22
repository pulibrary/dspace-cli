
module DSpace
  module CLI
    module Jobs

      class CSVUpdate < FileUpdate
        def self.build_csv(file_path)
          csv_table = CSV.parse(file.read, headers: true)
          file.close
          csv_table
        end

        def self.build_from_file(file_path:)
          csv_table = build_csv(file_path)

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
      end

    end
  end
end
