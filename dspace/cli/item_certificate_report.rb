module DSpace
  module CLI
    class ItemCertificateProgramReport
      attr_reader :items

      def initialize(items, output_file_path)
        @items = items
        @output_file_path = output_file_path
      end

      def self.root_path
        Pathname.new("#{File.dirname(__FILE__)}/../../reports/item_certificate_programs")
      end

      def self.headers
        %w[
          certificate_program
          submissionid
          item
          handle
          title
          classyear
          department
          state
          submitter
        ]
      end

      def items_by_program
        grouped = {}

        items.each do |item|
          item.certificate_programs.each do |program|
            grouped[program] = item
          end
        end

        grouped
      end

      def generate
        @output = CSV.generate do |csv|
          csv << self.class.headers

          items_by_program.each_pair do |certificate_program, item|
            item_state = if item.state.nil?
                           'ARCHIVED' # This is a placeholder for the ARCHIVED status
                         else
                           item.state
                         end

            submitter = item.submitter
            row = [
              certificate_program,
              item.submission_id,
              item.id,
              item.handle,
              item.title,
              item.class_year,
              item.department,
              item_state,
              submitter.email
            ]
            csv << row
          end
        end
      end

      def write
        generate if @output.nil?

        file = File.open(@output_file_path, 'wb:UTF-8')
        file.write(@output)
        file.close
      end
    end
  end
end
