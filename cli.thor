ROOT_PATH = File.dirname(__FILE__)

require File.join(ROOT_PATH, 'dspace', 'cli')

class Dataspace < Thor
  desc "import_metadata", "Import the metadata from a CSV file"
  method_option :file, type: :string, aliases: 'f'
  method_option :primary_column, type: :string, aliases: 'k'

  def import_metadata
    import_file_path = options[:file]
    primary_column = options[:primary_column]

    update = DSpace::CLI::Jobs::CSVUpdate.build_from_file(path: import_file_path, primary_column: primary_column)
    update.update_metadata
  end

  desc "export_metadata", "Export the metadata to a CSV file"
  method_option :file, type: :string, aliases: 'f'

  method_option :class_year, type: :string, aliases: 'y'
  method_option :department, type: :string, aliases: 'd'
  method_option :certificate_program, type: :string, aliases: 'p'
  def export_metadata
    export_file_path = options[:file]
    class_year = options[:class_year]
    department = options[:department]
    certificate_program = options[:certificate_program]

    query = Query.new
    query.find_by_class_year(class_year) unless class_year.nil?
    query = query.find_by_department(department) unless department.nil?
    query = query.find_by_certificate_program(certificate_program) unless certificate_program.nil?

    sub_query = query.find_members
    sub_query.result_set.export_metadata_to_file(csv_file_path: export_file_path)
  end

  desc "update_handles", "Import the handles from a CSV"
  method_option :file, type: :string, aliases: 'f'
  def update_handles
    csv_file_path = options[:file]

    job = DSpace::CLI::Jobs::BatchUpdateHandleJob.build_from_csv(file_path: csv_file_path)
    job.perform
  end
end
