# frozen_string_literal: true

require 'csv'
require 'pathname'
require 'logger'

module DSpace
  module CLI
    class Community < DSpaceObject
      # This needs to be a base query class
      def self.query_class
        nil
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

      def collections
        @obj.getCollections.map { |collection_obj| self.class.collection_class.new(collection_obj) }
      end

      def index
        super
        members.map(&:index)
      end

      def browse_index
        @browse_index ||= BrowseIndex.new(container: @obj, per_page: 1_000_000)
      end

      def remove_from_index
        super
        browse_index.delete_all_documents
      end

      # rubocop:disable Naming/AccessorMethodName
      def get_all_items
        member_objs = []

        member_iterator = @obj.getAllItems
        member_objs << member_iterator.next while member_iterator.hasNext

        member_objs
      end
      # rubocop:enable Naming/AccessorMethodName

      def item_members
        @item_members ||= get_all_items.map { |member_obj| Item.new(member_obj) }
      end

      def sub_communities
        @sub_communities ||= begin
                               community_obj_arr = @obj.getSubcommunities
                               return [] if community_obj_arr.nil?

                               community_objs = community_obj_arr.to_ary
                               community_objs.map { |community_obj| self.class.community_class.new(community_obj) }
                             end
      end

      def members
        @members ||= sub_communities + collections
      end
    end
  end
end
