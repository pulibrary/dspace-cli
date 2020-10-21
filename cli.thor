require File.join(File.dirname(__FILE__), 'dspace')

class Dspace < Thor
  desc 'import_metadata', 'Import Item metadata from a CSV file'
  method_option :file, type: :string, aliases: 'f'
  method_option :primary_column, type: :string, aliases: 'k'

  def import_metadata
    import_file_path = options[:file]
    primary_column = options[:primary_column]

    update = DSpace::CLI::Jobs::CSVUpdate.build_from_file(path: import_file_path, primary_column: primary_column)
    update.update_metadata
  end

  desc 'update_handles', 'Import the handles from a CSV'
  method_option :file, type: :string, aliases: 'f'
  method_option :primary_column, type: :string, aliases: 'k'
  def update_handles
    csv_file_path = options[:file]
    primary_column = options[:primary_column]

    job = DSpace::CLI::Jobs::BatchUpdateHandleJob.build_from_csv(file_path: csv_file_path, primary_column: primary_column)
    job.perform
  end
end

class Dataspace < Thor
  class SeniorTheses < Thor
    desc 'export_metadata', 'Export Item metadata to a CSV file'
    method_option :file, type: :string, aliases: 'f'
    method_option :class_year, type: :string, aliases: 'y'
    method_option :department, type: :string, aliases: 'd'
    method_option :certificate_program, type: :string, aliases: 'p'
    def export_metadata
      namespace 'senior_theses'

      export_file_path = options[:file]
      class_year = options[:class_year]
      department = options[:department]
      certificate_program = options[:certificate_program]

      query = DSpace::CLI::SeniorThesisQuery.new
      query.find_by_class_year(class_year) unless class_year.nil?
      query = query.find_by_department(department) unless department.nil?
      query = query.find_by_certificate_program(certificate_program) unless certificate_program.nil?
      query.result_set.export_metadata_to_file(csv_file_path: export_file_path)
    end

    desc 'export_community_metadata', 'Export Community Item metadata to CSV files'
    method_option :class_year, type: :string, aliases: 'y'
    def export_community_metadata
      namespace 'senior_theses'

      class_year = options[:class_year]

      DSpace::CLI::SeniorThesisCommunity.certificate_program_titles.each do |certificate_program|
        segment = certificate_program.downcase.gsub(/\s/, '_')
        export_file_path = "#{segment}.csv"

        query = DSpace::CLI::SeniorThesisQuery.new
        query.find_by_class_year(class_year) unless class_year.nil?
        query = query.find_by_certificate_program(certificate_program) unless certificate_program.nil?
        query.result_set.export_metadata_to_file(csv_file_path: export_file_path)
      end

      DSpace::CLI::SeniorThesisCommunity.collection_titles.each do |department|
        segment = department.downcase.gsub(/\s/, '_')
        export_file_path = "#{segment}.csv"

        query = DSpace::CLI::SeniorThesisQuery.new
        query.find_by_class_year(class_year) unless class_year.nil?
        query = query.find_by_department(department) unless department.nil?
        query.result_set.export_metadata_to_file(csv_file_path: export_file_path)
      end
    end

    desc 'export_policies', 'Export Bitstream policy metadata to a CSV file'
    method_option :file, type: :string, aliases: 'f'
    method_option :class_year, type: :string, aliases: 'y'
    method_option :department, type: :string, aliases: 'd'
    method_option :certificate_program, type: :string, aliases: 'p'
    def export_policies
      namespace 'senior_theses'

      export_file_path = options[:file]
      class_year = options[:class_year]
      department = options[:department]
      certificate_program = options[:certificate_program]

      query = DSpace::CLI::SeniorThesisQuery.new
      query.find_by_class_year(class_year) unless class_year.nil?
      query = query.find_by_department(department) unless department.nil?
      query = query.find_by_certificate_program(certificate_program) unless certificate_program.nil?
      query.result_set.export_policies_to_file(csv_file_path: export_file_path)
    end

    desc 'export_community_policies', 'Export Bitstream policy metadata for all Items in the Community to a CSV file'
    method_option :class_year, type: :string, aliases: 'y'
    def export_community_policies
      namespace 'senior_theses'

      class_year = options[:class_year]

      DSpace::CLI::SeniorThesisCommunity.certificate_program_titles.each do |certificate_program|
        segment = certificate_program.downcase.gsub(/\s/, '_')
        export_file_path = "#{segment}.csv"

        query = DSpace::CLI::SeniorThesisQuery.new
        query.find_by_class_year(class_year) unless class_year.nil?
        query = query.find_by_certificate_program(certificate_program) unless certificate_program.nil?
        query.result_set.export_policies_to_file(csv_file_path: export_file_path)
      end

      DSpace::CLI::SeniorThesisCommunity.collection_titles.each do |department|
        segment = department.downcase.gsub(/\s/, '_')
        export_file_path = "#{segment}.csv"

        query = DSpace::CLI::SeniorThesisQuery.new
        query.find_by_class_year(class_year) unless class_year.nil?
        query = query.find_by_department(department) unless department.nil?
        query.result_set.export_policies_to_file(csv_file_path: export_file_path)
      end
    end
  end
end
