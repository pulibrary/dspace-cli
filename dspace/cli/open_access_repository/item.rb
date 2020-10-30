module DSpace
  module CLI
    module OpenAccessRepository
      class Item < CLI::Item
        def self.author_uniqueid_field
          metadata_field_class.new('pu', 'author', 'uniqueid')
        end

        def author_uniqueids
          get_metadata_value(self.class.author_uniqueid_field.to_s)
        end

        def author_uniqueid
          author_uniqueids.first
        end

        def self.department_field
          metadata_field_class.new('pu', 'author', 'department')
        end

        def departments
          get_metadata_value(self.class.department_field.to_s)
        end

        def department
          departments.first
        end

        def self.symplectic_type_field
          metadata_field_class.new('pu', 'type', 'symplectic')
        end

        def symplectic_types
          get_metadata_value(self.class.symplectic_type_field.to_s)
        end

        def symplectic_type
          symplectic_types.first
        end

        def self.workflow_state_field
          metadata_field_class.new('pu', 'workflow', 'state')
        end

        def workflow_states
          get_metadata_value(self.class.workflow_state_field.to_s)
        end

        def workflow_state
          symplectic_types.first
        end

        def self.author_url_field
          metadata_field_class.new('pubs', 'author-url')
        end

        def self.awarded_date_field
          metadata_field_class.new('pubs', 'awarded-date')
        end

        def self.begin_page_field
          metadata_field_class.new('pubs', 'begin-page')
        end

        def self.book_author_type_field
          metadata_field_class.new('pubs', 'book-author-type')
        end

        def self.commissioning_body_field
          metadata_field_class.new('pubs', 'commissioning-body')
        end

        def self.confidential_field
          metadata_field_class.new('pubs', 'confidential')
        end

        def self.declined_field
          metadata_field_class.new('pubs', 'declined')
        end

        def self.deleted_field
          metadata_field_class.new('pubs', 'deleted')
        end

        def self.edition_field
          metadata_field_class.new('pubs', 'edition')
        end

        def self.elements_source_field
          metadata_field_class.new('pubs', 'elements-source')
        end

        def self.end_page_field
          metadata_field_class.new('pubs', 'end-page')
        end

        def self.finished_date_field
          metadata_field_class.new('pubs', 'finish-date')
        end

        def self.issue_field
          metadata_field_class.new('pubs', 'issue')
        end

        def self.merge_from_field
          metadata_field_class.new('pubs', 'merge-from')
        end

        def self.merge_to_field
          metadata_field_class.new('pubs', 'merge-to')
        end

        def self.notes_field
          metadata_field_class.new('pubs', 'notes')
        end

        def self.organisational_group_field
          metadata_field_class.new('pubs', 'organisational-group')
        end

        def self.patent_status_field
          metadata_field_class.new('pubs', 'patent-status')
        end

        def self.place_of_publication_field
          metadata_field_class.new('pubs', 'place-of-publication')
        end

        def self.publication_status_field
          metadata_field_class.new('pubs', 'publication-status')
        end

        def self.publisher_url_field
          metadata_field_class.new('pubs', 'publisher-url')
        end

        def self.start_date_field
          metadata_field_class.new('pubs', 'start-date')
        end

        def self.version_field
          metadata_field_class.new('pubs', 'version')
        end

        def self.volume_field
          metadata_field_class.new('pubs', 'volume')
        end

        # Accessors

        def self.collection_class
          CLI::OpenAccessRepository::Collection
        end

        def find_collections_for_departments
          collections = []
          departments.each do |department|
            collection = self.class.collection_class.find_for_department(department)
            collections << collection unless collection.nil?
          end
          collections
        end
      end
    end
  end
end