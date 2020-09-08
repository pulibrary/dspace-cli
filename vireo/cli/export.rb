require 'roo'
require 'csv'
require 'ostruct'

module Vireo
  module CLI
    class Export

      def initialize(csv:, year:)
        @csv = csv
        @year = year
      end

      def self.spreadsheet_headers
        [
          'ID',
          'Primary document',
          'Title',
          'Student ID',
          'Student name',
          'Language',
          'Thesis Type',
          'Approval date',
          'Submission date',
          'Advisors',
          'Student email',
          'Department',
          'Certificate Program'
        ]
      end

      def self.build_from_spreadsheet(file_path:, year:)
        xlsx = Roo::Excelx.new(file_path)

        csv_data = CSV.generate do |csv|
          # This uses the original headers
          csv << spreadsheet_headers

          xlsx_rows = []
          xlsx.each_row_streaming do |row|
            xlsx_rows << row
          end

          imported_rows = xlsx_rows[1..-1]
          imported_rows.each do |row|
            values = row.map do |cell|
              if cell.is_a?(Float)
                cell.value.to_i.to_s
              else
                cell.value.to_s
              end
            end

            csv << values
          end
        end
        parsed = CSV.parse(csv_data)

        self.new(csv: parsed, year: year)
      end

      def csv_headers
        @csv.first
      end

      def csv_rows
        @csv[1..-1]
      end

      def csv_submission_id_column
        csv_headers.index('ID')
      end

      def csv_author_id_column
        csv_headers.index('Student ID')
      end

      def csv_author_column
        csv_headers.index('Student name')
      end

      def csv_department_column
        csv_headers.index('Department')
      end

      def csv_certificate_program_column
        csv_headers.index('Certificate Program')
      end

      def submission_metadata
        csv_rows.map do |row|
          id_value = row[headers.index('ID')]
          id = id_value.to_i.to_s

          primary_document = row[headers.index('Primary document')]
          author_id = row[headers.index('Student ID')]
          department = row[headers.index('Department')]
          certificate = row[headers.index('Certificate Program')]

          values = {
            id: id,
            primary_document: primary_document,
            class_year: @year,
            author_id: author_id,
            department: department,
            certificate: certificate
          }

          OpenStruct.new(values)
        end
      end

      def self.batch_import_headers
        [
          'submissionid',
          'title',
          'authorid',
          'author',
          'department',
          'certificate_program'
        ]
      end

      def build_batch_import

        @batch_import_csv ||= CSV.generate do |import_csv|
          import_csv << self.class.batch_import_headers

          csv_rows.map do |row|

            submission_id = row[csv_submission_id_column]
            author_id = row[csv_author_id_column]
            author = row[csv_author_column]
            department = row[csv_department_column]
            certificate_program = row[csv_certificate_program_column]

            import_row = [
              submission_id,
              title,
              author_id,
              author,
              department,
              certificate_program
            ]

            import_csv << import_row
          end
        end
      end

      def self.batch_import_path
        Pathname.new("#{File.dirname(__FILE__)}/../../batch_imports")
      end

      def write_batch_import(output_file_name)
        build_batch_import if @batch_import_csv.nil?

        output_file_path = File.join(self.class.batch_import_path, output_file_name)

        file = File.open(output_file_path, 'wb:UTF-8')
        file.write(@batch_import_csv)
        file.close
      end

    end
  end
end
