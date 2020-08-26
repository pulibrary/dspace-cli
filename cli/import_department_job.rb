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

  def perform
    @logger.info("Importing the department #{name} #{year}...")
    vireo = VireoExport.build_from_spreadsheet(file_path: vireo_export_path, year: @year)

    vireo.submission_metadata.each do |metadata|
      submission = find_submission_by_id(metadata.id)
      @logger.info("Importing the Vireo metadata for submission #{metadata.id}...")

      submission.class_year = metadata.class_year
      submission.author_id = metadata.author_id
      submission.department = metadata.department
      submission.certificate = metadata.certificate
    end
  end
end

