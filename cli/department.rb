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
      submission.department = metadata.department
      submission.certificate = metadata.certificate
    end
  end

  def initialize(name:, year:)
    @name = name
    @year = year
  end
end

