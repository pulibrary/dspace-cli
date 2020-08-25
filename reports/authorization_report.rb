# frozen_string_literal: true

require 'csv'

# Namespace for reporting classes
module Reports
  java_import org.dspace.core.Constants
  java_import org.dspace.authorize.AuthorizeManager

  # Class for generating reporting the authorization policies
  class AuthorizationReport
    def self.build(handle)
      community = DSpace.fromString(handle)
      new(community)
    end

    def initialize(community)
      @community = community
      @rows = []
    end

    def self.kernel
      DSpace
    end

    def self.headers
      %w[url ARK title authorization_id authorization_type authorization_name]
    end

    def self.host
      'dataspace.princeton.edu'
    end

    def self.protocol
      'https'
    end

    def self.title_field
      Metadata::Field.new('dc', 'title')
    end

    def self.year_field
      Metadata::Field.new('pu', 'date', 'classyear')
    end

    def collections
      @collections ||= begin
                         objects = DCommunity.getCollections(@community)
                         objects.map { |obj| DCollection.new(obj) }
                       end
    end

    def items
      @items ||= collections.map(&:items).flatten
    end

    def select_items(class_year: '2020')
      return @select_items unless @select_items.nil?

      select = []

      items.each do |item|
        class_years = item.getMetadataByMetadataString(self.class.year_field.to_s).collect(&:value)
        item_year = class_years.first

        select << item if item_year == class_year
      end

      @select_items = select
    end

    def rows
      return @rows unless @rows.empty?

      @rows << self.class.headers

      select_items.each do |item|
        handle = item.getHandle
        url = "#{self.class.protocol}://#{self.class.host}/handle/#{handle}"

        titles = item.getMetadataByMetadataString(self.class.title_field.to_s).collect(&:value)
        title = titles.first

        policies = Java::OrgDspaceAuthorize::AuthorizeManager.getPolicies(self.class.kernel.context, item)
        policies.each do |policy|
          policy_group = policy.getGroup
          row = [url, handle, title, policy.getID, policy.getActionText, policy_group.getName]
          @rows << row
        end
      end

      @rows
    end

    def csv
      return @csv unless @csv.nil?

      @csv = CSV.generate do |csv|
        rows.each do |row|
          csv << row
        end
      end
    end

    def write(file_path)
      File.write(file_path, csv)
    end
  end
end
