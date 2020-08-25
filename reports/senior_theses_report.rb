# frozen_string_literal: true

require 'csv'

# Namespace for reporting classes
module Reports
  # Class for generating reporting the senior thesis metadata
  class SeniorThesesReport
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
      ['url', 'ARK', 'title', 'pu.mudd.walkin']
    end

    def self.title_field
      Metadata::Field.new('dc', 'title')
    end

    def self.access_field
      Metadata::Field.new('pu', 'mudd', 'walkin')
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

    def filtered_items
      return @filtered_items unless @filtered_items.nil?

      filtered = []

      items.each do |item|
        class_years = item.getMetadataByMetadataString(self.class.year_field.to_s).collect(&:value)
        class_year = class_years.first

        access_values = item.getMetadataByMetadataString(self.class.access_field.to_s).collect(&:value)
        access = access_values.first
        filtered << item if class_year == '2020' && access =~ /yes/i
      end

      @filtered_items = filtered
    end

    def self.protocol
      'https'
    end

    def self.host
      'dataspace.princeton.edu'
    end

    def rows
      return @rows unless @rows.empty?

      @rows << self.class.headers

      filtered_items.each do |item|
        handle = item.getHandle
        url = "#{self.class.protocol}://#{self.class.host}/handle/#{handle}"

        titles = item.getMetadataByMetadataString(self.class.title_field.to_s).collect(&:value)
        title = titles.first

        access_values = item.getMetadataByMetadataString(self.class.access_field.to_s).collect(&:value)
        access = access_values.first

        row = [url, handle, title, access]
        @rows << row
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
