# frozen_string_literal: true

module DSpace
  module CLI
    # This models the DSpace entity org.dspace.content.WorkspaceItem
    class WorkspaceItem
      java_import(org.dspace.storage.rdbms.DatabaseManager)
      java_import(org.dspace.content.WorkspaceItem)

      attr_reader :model

      def self.kernel
        ::DSpace
      end

      def self.model_class
        org.dspace.content.WorkspaceItem
      end

      def self.build_model(row:)
        constructors = model_class.java_class.declared_constructors
        constructors.each do |c|
          c.accessible = true
          return c.new_instance(kernel.context, row).to_java
        end
      end

      def self.database_manager
        org.dspace.storage.rdbms.DatabaseManager
      end

      def self.create(collection:, item:)
        workspace_item_row = database_manager.row("workspaceitem")

        workspace_item_row.setColumn("item_id", item.id)
        workspace_item_row.setColumn("collection_id", collection.id)

        database_manager.insert(kernel.context, workspace_item_row)

        model = build_model(row: workspace_item_row)

        new(model)
      end

      def initialize(model)
        @model = model
      end

      def id
        @model.getID
      end

      def update
        @model.update
        self.class.kernel.commit
        self
      end
    end
  end
end
