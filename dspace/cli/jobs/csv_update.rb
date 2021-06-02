# frozen_string_literal: true

require 'csv'

module DSpace
  module CLI
    module Jobs
      # Class modeling the updates mapping CSV row values to Item metadata fields
      class CSVUpdate < FileUpdate
        def self.parse_csv(file_path)
          file = File.new(file_path, 'r:UTF-8')
          CSV.parse(file, headers: true)
        end

        def self.build_from_file(path:, primary_column:)
          relative_path = if !File.exist?(path)
                            File.join(File.dirname(__FILE__), '..', '..', '..', 'imports', 'metadata', path)
                          else
                            path
                          end
          absolute_path = Pathname.new(relative_path)
          csv_table = parse_csv(absolute_path)

          updates = []

          table_values = csv_table.to_a
          rows = table_values[1..-1]
          rows.each do |row|
            value = { primary_column: primary_column }

            csv_table.headers.each do |column|
              column_index = csv_table.headers.find_index(column)
              cell = row[column_index] || ''
              cell_values = cell.split(/;/)

              value[column] = if cell_values.length < 2
                                cell_values.first
                              else
                                cell_values
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

        def update_metadata
          job = BatchUpdateMetadataJob.build(self)
          job.perform
        end
      end
    end
  end
end
