# frozen_string_literal: true

module DSpace
  module CLI
    class Collection
      java_import org.dspace.storage.rdbms.DatabaseManager
      java_import org.dspace.handle.HandleManager
      attr_reader :obj

      def self.kernel
        ::DSpace
      end

      def self.title_field
        MetadataField.new('dc', 'title')
      end

      def initialize(obj)
        @obj = obj
      end

      def id
        @obj.getID
      end

      def handle
        @obj.getHandle
      end

      # This needs to be abstracted
      # rubocop:disable Naming/MethodName
      def getMetadataByMetadataString(metadata_field)
        @obj.getMetadataByMetadataString(metadata_field)
      end
      # rubocop:enable Naming/MethodName

      def titles
        @obj.getMetadataByMetadataString(self.class.title_field.to_s).collect(&:value)
      end

      def title
        titles.first
      end

      # rubocop:disable Naming/MethodName
      def removeItem(item)
        database_statement = 'DELETE FROM collection2item WHERE collection_id= ? AND item_id= ?'
        Java::OrgDspaceStorageRdbms::DatabaseManager.updateQuery(self.class.kernel.context, database_statement, id, item.id)
        self.class.kernel.commit
      end
      # rubocop:enable Naming/MethodName

      def remove_item(item)
        removeItem(item)
      end

      # rubocop:disable Naming/MethodName
      def addItem(item)
        @obj.addItem(item.obj)
      end
      # rubocop:enable Naming/MethodName

      def add_item(item)
        addItem(item)
      end

      def update
        @obj.update
        self.class.kernel.commit
      end
    end
  end
end
