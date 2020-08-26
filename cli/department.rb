require 'roo'
require 'csv'
require 'ostruct'

class Department
  attr_reader :name

  def self.root_path
    value = File.dirname(__FILE__)
    File.join(value, '..')
  end

  def dir_name
    @name.downcase.gsub(/\s+/, '_')
  end

  def dir_path
    @dir_path ||= File.join(self.class.root_path, 'imports', 'senior_theses', dir_name)
  end

  def submission_dir_paths
    entries = Dir.entries(dir_path)
    entries.select { |f| f.include?('submission_') }
  end

  def submissions
    @submissions ||= submission_dir_paths.map do |path|
      segments = path.split('_')
      submission_id = segments.last
      Submission.new(id: submission_id, department: dir_name)
    end
  end

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

  def vireo_export_path
    value = File.join(dir_path, 'ExcelExport.xlsx')
    Pathname.new(value)
  end

  def find_submission_by_id(value)
    submissions.each do |s|
      return s if s.id == value
    end
  end

  # Default is #{dir_path}/ExcelExport.xlsx
  def import_vireo_metadata
    vireo = VireoExport.build_from_spreadsheet(file_path: vireo_export_path, year: @year)

    vireo.submission_metadata.each do |metadata|
      submission = find_submission_by_id(metadata.id)

      submission.class_year = metadata.class_year
      submission.author_id = metadata.author_id
      submission.department = metadata.department_value
      submission.certificate = metadata.certificate
    end
  end

  def initialize(name:, year:)
    @name = name
    @year = year
  end
end

