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

  def self.import_dir_path
    @import_dir_path ||= File.join(root_path, 'imports', 'senior_theses')
  end

  def dir_path
    @dir_path ||= File.join(self.class.import_dir_path, dir_name)
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

  def generate_cover_pages
    submissions.each do |submission|
      submission.generate_cover_page
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

  def find_submission_by_normal_name(value)
    submissions.each do |s|
      normal_title = s.title.gsub(/[":]/, '').strip
      normal_value = value.gsub(/[":]/, '').strip

      return s if normal_title == normal_value
    end

    nil
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

  def self.restrictions_export_path
    value = File.join(import_dir_path, 'restrictions_export.xlsx')
    Pathname.new(value)
  end

  def import_restrictions_metadata
    restrictions = RestrictionsExport.build_from_spreadsheet(file_path: self.class.restrictions_export_path, year: @year)

    restrictions.submission_metadata.each do |metadata|
      title_match = /^(.+?)\s\-\s(.+?)\.xml$/.match(metadata.name)
      normal_title = title_match[1]
      submission = find_submission_by_normal_name(normal_title)
      next if submission.nil?

      if metadata.embargoed?
        submission.embargo_terms = metadata.embargo_date
        submission.embargo_lift = metadata.embargo_date
      end

      if metadata.mudd_access_only?
        submission.mudd_walkin = 'Yes'
        # This needs to be a constant
        submission.rights = 'Walk-in Access. This thesis can only be viewed on computer terminals at the <a href=http://mudd.princeton.edu>Mudd Manuscript Library</a>.'
      end
    end
  end

  def initialize(name:, year:)
    @name = name
    @year = year
  end
end

