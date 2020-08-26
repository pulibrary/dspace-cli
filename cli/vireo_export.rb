require 'roo'
require 'csv'
require 'ostruct'

class VireoExport
  def initialize(csv:, year:)
    @csv = csv
    @year = year
  end

  def self.headers
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
      csv << headers

      xlsx_rows = []
      xlsx.each_row_streaming do |row|
        xlsx_rows << row
      end
      # xlsx_headers = xlsx_rows.first
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

  def submission_metadata
    headers = @csv.first
    rows = @csv[1..-1]

    rows.map do |row|
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
end

