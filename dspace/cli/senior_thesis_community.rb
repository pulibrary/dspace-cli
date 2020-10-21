require 'csv'
require 'logger'
require 'ostruct'
require 'pathname'
require 'yaml'

module DSpace
  module CLI
    # Class modeling Communities containing Senior Thesis Items as members
    class SeniorThesisCommunity < DSpace::Core::Community
      class Configuration < OpenStruct
        def self.build_from_file(file_path)
          fh = File.new(file_path, 'rb')
          file_content = fh.read
          yaml_values = YAML.safe_load(file_content)
          values = if yaml_values.is_a?(Hash)
                     yaml_values
                   else
                     yaml_values.to_ruby
                   end

          built = new(values)
          fh.close

          built
        end
      end

      def self.configuration_file
        File.join(File.dirname(__FILE__), '..', '..', 'config', 'senior_theses.yml')
      end

      def self.configuration
        @configuration ||= Configuration.build_from_file(configuration_file)
      end

      # This needs to be restructured to parse from a configuration file
      def self.certificate_program_titles
        configuration.certificate_programs
      end

      # This needs to be restructured to parse from a configuration file
      def self.collection_titles
        configuration.departments
      end

      def self.kernel
        ::DSpace
      end

      def self.query_class
        SeniorThesisQuery
      end

      def self.class_year_field
        MetadataField.new('pu', 'date', 'classyear')
      end

      def self.embargo_date_field
        MetadataField.new('pu', 'embargo', 'lift')
      end

      def self.walk_in_access_field
        MetadataField.new('pu', 'mudd', 'walkin')
      end

      def self.query
        query_class.new
      end

      def find_children
        return if @results.empty?

        selected_results = @results.map(&:members)
        self.class.new(selected_results.flatten, self)
      end

      def self.find_items(metadata_field, value)
        query = query_class.new
        query.find_items(metadata_field, value)
      end

      def self.find_by_class_year(value)
        find_items(class_year_field.to_s, value)
      end

      def self.find_by_embargo_date(value)
        find_items(embargo_date_field.to_s, value)
      end

      def self.find_by_walk_in_access(value)
        find_items(walk_in_access_field.to_s, value)
      end

      def self.export_departments(year)
        collection_titles.each do |department_title|
          year_query = query.find_by_class_year(year)
          dept_query = year_query.find_by_department(department_title)
          dept_query.results.each do |item|
            item.export
          end
        end
      end

      def self.write_item_state_reports(year)
        collection_titles.each do |department_title|
          year_query = query.find_by_class_year(year)
          dept_query = year_query.find_by_department(department_title)
          report_name = "#{DSpace::CLI::ResultSet.normalize_department_title(department_title)}.csv"
          report = dept_query.result_set.item_state_report(report_name)
          report.write
        end

        certificate_program_titles.each do |program_title|
          year_query = query.find_by_class_year(year)
          program_query = year_query.find_by_certificate_program(program_title)
          report_name = "#{DSpace::CLI::ResultSet.normalize_department_title(program_title)}.csv"
          report = program_query.result_set.item_state_report(report_name)
          report.write
        end
      end

      def self.write_item_author_reports(year)
        collection_titles.each do |department_title|
          year_query = query.find_by_class_year(year)
          dept_query = year_query.find_by_department(department_title)
          report_name = "#{DSpace::CLI::ResultSet.normalize_department_title(department_title)}.csv"
          report = dept_query.result_set.item_author_report(report_name)
          report.write
        end

        certificate_program_titles.each do |program_title|
          year_query = query.find_by_class_year(year)
          program_query = year_query.find_by_certificate_program(program_title)
          report_name = "#{DSpace::CLI::ResultSet.normalize_department_title(program_title)}.csv"
          report = program_query.result_set.item_author_report(report_name)
          report.write
        end
      end

      def self.write_item_certificate_program_reports(year)
        collection_titles.each do |department_title|
          year_query = query.find_by_class_year(year)
          dept_query = year_query.find_by_department(department_title)
          report_name = "#{DSpace::CLI::ResultSet.normalize_department_title(department_title)}.csv"
          report = dept_query.result_set.item_certificate_program_report(report_name)
          report.write
        end

        certificate_program_titles.each do |program_title|
          year_query = query.find_by_class_year(year)
          program_query = year_query.find_by_certificate_program(program_title)
          report_name = "#{DSpace::CLI::ResultSet.normalize_department_title(program_title)}.csv"
          report = program_query.result_set.item_certificate_program_report(report_name)
          report.write
        end
      end
    end
  end
end
