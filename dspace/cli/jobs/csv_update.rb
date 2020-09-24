require 'csv'

module DSpace
  module CLI
    module Jobs
      class CSVUpdate < FileUpdate
        def self.parse_csv(file_path)
          file = File.new(file_path, 'r:UTF-8')
          csv_table = CSV.parse(file, headers: true)

          csv_table
        end

        def self.build_from_file(path:)
          if !File.exist?(path)
            relative_path = File.join(File.dirname(__FILE__), '..', '..', '..', 'imports', 'metadata', path)
          else
            relative_path = path
          end
          absolute_path = Pathname.new(relative_path)
          csv_table = parse_csv(absolute_path)

          updates = []

          table_values = csv_table.to_a
          rows = table_values[1..-1]
          rows.each do |row|
            value = {}
            csv_table.headers.each do |column|
              column_index = csv_table.headers.find_index(column)
              cell = row[column_index] || ""
              cell_values = cell.split(/;/)

              if cell_values.length < 2
                value[column] = cell_values.first
              else
                value[column] = cell_values
              end
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
