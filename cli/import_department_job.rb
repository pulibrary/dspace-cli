class ImportDepartmentJob
  attr_reader :name, :year

  def initialize(name:, year:, logger:)
    @name = name
    @year = year
    @logger = logger
    @department = Department.new(name: name, year: year)
  end

  def perform
    import_vireo_metadata
  end

  def vireo_export_path
    @department.vireo_export_path
  end

  def find_submission_by_id(id)
    @department.find_submission_by_id(id)
  end

  def find_submission_by_normal_name(name)
    @department.find_submission_by_normal_name(name)
  end

  def self.restrictions_export_path
    Department.restrictions_export_path
  end

  # This should be refactored using a block/yield pattern with Department#import_vireo_metadata
  def generate_cover_pages
    @department.submissions.each do |submission|
      @logger.info("Generating the cover page for submission #{submission.id}...")
      submission.generate_cover_page
    end
  end

  # This should be refactored using a block/yield pattern with Department#import_vireo_metadata
  def import_restrictions_metadata
    restrictions = RestrictionsExport.build_from_spreadsheet(file_path: self.class.restrictions_export_path, year: @year)

    restrictions.submission_metadata.each do |metadata|
      title_match = /^(.+?)\s\-\s(.+?)\.xml$/.match(metadata.name)
      normal_title = title_match[1]
      submission = find_submission_by_normal_name(normal_title)
      next if submission.nil?

      @logger.info("Importing the restrictions metadata for submission #{submission.id}...")

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

  # This should be refactored using a block/yield pattern with Department#import_vireo_metadata
  def import_vireo_metadata
    vireo = VireoExport.build_from_spreadsheet(file_path: vireo_export_path, year: @year)

    vireo.submission_metadata.each do |metadata|
      submission = find_submission_by_id(metadata.id)
      @logger.info("Importing the Vireo metadata for submission #{submission.id}...")

      submission.class_year = metadata.class_year
      submission.author_id = metadata.author_id
      submission.department = metadata.department
      submission.certificate = metadata.certificate
    end
  end

  def perform
    @logger.info("Importing the department #{name} #{year}...")
    generate_cover_pages
    import_vireo_metadata
    import_restrictions_metadata
  end
end

