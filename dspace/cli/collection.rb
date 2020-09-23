# frozen_string_literal: true

module DSpace
  module CLI
    class Collection < DSpaceObject
      java_import org.dspace.storage.rdbms.DatabaseManager
      java_import org.dspace.handle.HandleManager

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

      def get_all_items
        member_objs = []

        member_iterator = @obj.getAllItems
        member_objs << member_iterator.next while member_iterator.hasNext

        member_objs
      end

      def members
        @members ||= get_all_items.map { |member_obj| Item.new(member_obj) }
      end

      def self.workflow_item_class
        DSpace::CLI::WorkflowItem
      end

      def workflow_items
        values = Java::OrgDspaceWorkflow::WorkflowItem.findByCollection(self.class.kernel.context, @obj)
        workflow_objs = values.to_a
        return workflow_objs if workflow_objs.empty?

        workflow_objs.map do |workflow_obj|
          self.class.workflow_item_class.new(workflow_obj)
        end
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
    end
  end
end
