# frozen_string_literal: true

require 'csv'
require 'pathname'
require 'logger'

module DSpace
  module CLI
    class Community
      def self.kernel
        ::DSpace
      end

      # This needs to be a base query class
      def self.query_class
        nil
      end

      def initialize(obj)
        @obj = obj
      end

      def self.query
        query_class.new
      end

      def self.find_items(metadata_field, value)
        query = query_class.new
        query.find_items(metadata_field, value)
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
    end
  end
end
