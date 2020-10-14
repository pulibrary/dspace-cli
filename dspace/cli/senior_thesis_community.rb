require 'csv'
require 'pathname'
require 'logger'

module DSpace
  module CLI
    class SeniorThesisCommunity < DSpace::Core::Community
      # This needs to be restructured to parse from a configuration file
      def self.certificate_program_titles
        [
          'Creative Writing Program'
        ]
      end

      # This needs to be restructured to parse from a configuration file
      def self.collection_titles
        [
          'African American Studies',
          'Anthropology',
          'Architecture School',
          'Art and Archaeology',
          'Astrophysical Sciences',
          'Chemical and Biological Engineering',
          'Chemistry',
          'Civil and Environmental Engineering',
          'Classics',
          'Comparative Literature',
          'Computer Science',
          'East Asian Studies',
          'Ecology and Evolutionary Biology',
          'Economics',
          'Electrical Engineering',
          'English',
          'French and Italian',
          'Geosciences',
          'German',
          'History',
          'Independent Concentration',
          'Mathematics',
          'Mechanical and Aerospace Engineering',
          'Molecular Biology',
          'Near Eastern Studies',
          'Neuroscience',
          'Operations Research and Financial Engineering',
          'Philosophy',
          'Physics',
          'Politics',
          'Woodrow Wilson School', # This needs to be renamed to the Princeton School
          'Psychology',
          'Slavic Languages and Literature',
          'Sociology',
          'Spanish and Portuguese'
        ]
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

      def initialize(obj)
        @obj = obj
      end

      def self.query
        query_class.new
      end

      def find_children
        if !@results.empty?
          selected_results = @results.map(&:members)

          return self.class.new(selected_results.flatten, self)
        end
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
