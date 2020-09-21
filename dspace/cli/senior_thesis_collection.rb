module DSpace
  module CLI
    class SeniorThesisCollection
      java_import org.dspace.storage.rdbms.DatabaseManager
      java_import org.dspace.handle.HandleManager
      attr_reader :obj

      def self.kernel
        ::DSpace
      end

      # This needs to be restructured to parse a configuration file
      def self.department_to_collection_map
        {
          'Comparative Literature' => '88435/dsp01rf55z7763',
          'English' => '88435/dsp01qf85nb35s'
        }
      end

      def self.find_for_department(department)
        return unless department_to_collection_map.key?(department)

        handle = department_to_collection_map[department]
        obj = Java::OrgDspaceHandle::HandleManager.resolveToObject(kernel.context, handle)
        return if obj.nil?

        new(obj)
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
      def getMetadataByMetadataString(metadata_field)
        @obj.getMetadataByMetadataString(metadata_field)
      end

      def titles
        @obj.getMetadataByMetadataString(self.class.title_field.to_s).collect { |v| v.value }
      end

      def title
        titles.first
      end

      def removeItem(item)
        database_statement = 'DELETE FROM collection2item WHERE collection_id= ? AND item_id= ?'
        Java::OrgDspaceStorageRdbms::DatabaseManager.updateQuery(self.class.kernel.context, database_statement, id, item.id)
        self.class.kernel.commit
      end

      def remove_item(item)
        removeItem(item)
      end

      def addItem(item)
        @obj.addItem(item.obj)
      end

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
