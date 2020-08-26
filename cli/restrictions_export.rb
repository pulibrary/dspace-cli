require 'roo'
require 'csv'
require 'ostruct'

class RestrictionsExport
  def initialize(csv:, year:)
    @csv = csv
    @year = year
  end

  def self.headers
    [
      'Name',
      'Submitted By',
      'Created',
      'Class Year',
      'Department',
      'Adviser',
      'Embargo Years',
      'Walk In Access',
      'Initial Review',
      'Adviser Comments Status',
      'Adviser Comments',
      'ODOCReview',
      'Confirmation Sent',
      'Approval Notification Sent',
      'Mudd Status',
      'Request Type',
      'Notify Faculty Adviser',
      'Thesis Uploaded',
      'Check Thesis Uploaded',
      'SetFormLink',
      'Item Type',
      'Path'
    ]
  end

  def self.build_from_spreadsheet(file_path:, year:)
    xlsx = Roo::Excelx.new(file_path)

    csv_data = CSV.generate do |csv|
      csv << headers

      xlsx_rows = []
      xlsx.each_row_streaming do |row|
        xlsx_rows << row
      end
      # xlsx_headers = xlsx_rows.first
      imported_rows = xlsx_rows[1..-1]

      imported_rows.each do |row|
        values = row.map do |cell|
          if cell.is_a?(Float)
            cell.value.to_i.to_s
          else
            cell.value.to_s
          end
        end

        csv << values
      end
    end
    parsed = CSV.parse(csv_data)

    self.new(csv: parsed, year: year)
  end

  class Metadata < OpenStruct
    def mudd_access_only?
      self.walk_in_access.downcase == 'yes'
    end

    def embargoed?
      self.embargo_years != 'N/A'
    end
  end

  def submission_metadata
    headers = @csv.first
    rows = @csv[1..-1]

    rows.map do |row|
      # 'Behind Glass'_ War in the Short Fiction of J. D. Salinger - Sarah Kate Barnette.xml
      # LEADD_ Learning Efficient and Accurate Disease Diagnoses - Joe Zhang.xml
      name = row[headers.index('Name')]
      walk_in_access = row[headers.index('Walk In Access')]
      embargo_years = row[headers.index('Embargo Years')]

      embargo_year = @year.to_i + embargo_years.to_i
      embargo_date = "7/1/#{embargo_year}"

      values = {
        name: name,
        walk_in_access: walk_in_access,
        embargo_years: embargo_years,
        embargo_date: embargo_date
      }

      Metadata.new(values)
    end
  end
end

