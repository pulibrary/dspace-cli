module DSpace
  module CLI
    class SeniorThesisItem < Item
      def self.department_field
        MetadataField.new('pu', 'department')
      end

      def self.certificate_program_field
        MetadataField.new('pu', 'certificate')
      end

      def self.class_year_field
        MetadataField.new('pu', 'date', 'classyear')
      end

      def self.submission_id_field
        MetadataField.new('pu', 'submissionid')
      end

      def departments
        @obj.getMetadataByMetadataString(self.class.department_field.to_s).collect { |v| v.value }
      end

      def department
        departments.first
      end

      def certificate_programs
        @obj.getMetadataByMetadataString(self.class.certificate_program_field.to_s).collect { |v| v.value }
      end

      def certificate_program
        certificate_programs.first
      end

      def class_years
        @obj.getMetadataByMetadataString(self.class.class_year_field.to_s).collect { |v| v.value }
      end

      def class_year
        class_years.first
      end

      def self.collection_class
        SeniorThesisCollection
      end

      def find_collections_for_departments
        collections = []
        departments.each do |department|
          collection = self.class.collection_class.find_for_department(department)
          collections << collection unless collection.nil?
        end
        collections
      end

      def find_collections_for_certificate_programs
        collections = []
        certificate_programs.each do |program|
          collection = self.class.find_collection_by_title(program)
          collections << collection unless collection.nil?
        end
        collections
      end
    end
  end
end
