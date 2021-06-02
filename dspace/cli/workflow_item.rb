# frozen_string_literal: true

module DSpace
  module CLI
    # This models the DSpace entity org.dspace.workflow.WorkflowItem
    class WorkflowItem
      java_import org.dspace.eperson.EPerson
      java_import org.dspace.handle.HandleManager
      java_import org.dspace.storage.rdbms.DatabaseManager
      java_import org.dspace.workflow.WorkflowManager

      attr_reader :model, :state

      def self.kernel
        ::DSpace
      end

      def self.model_class
        org.dspace.workflow.WorkflowItem
      end

      def self.workflow_manager
        org.dspace.workflow.WorkflowManager
      end

      def self.find_by_submitter(eperson)
        models = model_class.findByEPerson(kernel.context, eperson.model)
        models.map { |m| new(m) }
      end

      def self.find_by_submitter_email(email)
        epeople = CLI::EPerson.find_by_email(email)
        results = epeople.map { |eperson| find_by_owner(eperson) }
        results.flatten
      end

      # Constructor
      # @param model [org.dspace.workflow.WorkflowItem]
      def initialize(model)
        @model = model
        # Synchronize the initial state (otherwise this gets cached)
        @state = @model.getState
      end

      def id
        @model.getID
      end

      # Deprecated alias
      def obj
        @model
      end

      def update
        # Please note, this updates the related Item object
        @model.update
        self.class.kernel.commit
        self
      end

      def delete
        @model.deleteWrapper
        self.class.kernel.commit
        @model = nil
      end

      def self.update_statement
        <<-SQL
        UPDATE workflowitem
          SET state = ?
          WHERE workflow_id = ?
        SQL
      end

      def self.database_manager
        Java::OrgDspaceStorageRdbms::DatabaseManager
      end

      def self.update_query(statement, *params)
        database_manager.updateQuery(kernel.context, statement, *params)
      end

      def state=(value)
        # This does not work
        # @model.setState(value)

        @state = value
        update_state
        self.class.kernel.commit
        state
      end

      def owner
        @model.getOwner
      end

      def owner=(value)
        @model.setOwner(value)
        update
      end

      def self.delete_query
        'DELETE FROM tasklistitem WHERE eperson_id = ? AND workflow_id = ?'
      end

      def self.delete_from_database(eperson_id, workflow_id)
        database_manager.updateQuery(kernel.context, delete_query, eperson_id.to_java, workflow_id.to_java)
        kernel.commit
      end

      def self.select_tasks_query
        <<-SQL
        SELECT eperson_id FROM tasklistitem
          WHERE workflow_id = ?
        SQL
      end

      def self.query(database_query, *params)
        database_manager.query(kernel.context, database_query, *params)
      end

      def self.eperson_class
        Java::OrgDspaceEperson::EPerson
      end

      def task_users
        database_query = self.class.select_tasks_query
        rows = self.class.query(database_query, id)
        rows.map { |row| self.class.eperson_class.build(row['eperson_id']) }
      end

      def create_workflow_tasks(epeople)
        epeople.each do |eperson|
          table_row = self.class.database_manager.row('tasklistitem')
          table_row.setColumn('eperson_id', eperson.getID)
          table_row.setColumn('workflow_id', id)

          self.class.database_manager.insert(self.class.kernel.context, table_row)
          self.class.kernel.commit

          self.state = self.class.workflow_manager::WFSTATE_STEP1POOL
          update
        end
      end

      def delete_workflow_tasks(epeople)
        epeople.each do |eperson|
          self.class.delete_from_database(eperson.getID, id)
        end
      end

      def remove_task_pool_users(emails)
        users = emails.map do |email|
          Java::OrgDspaceEperson::EPerson.findByEmail(self.class.kernel.context, email)
        end
        epeople = users.reject(&:nil?)

        delete_workflow_tasks(epeople)
      end

      def remove_task_pool_user(email)
        remove_task_pool_users([email])
      end

      def add_task_pool_users(emails)
        users = emails.map do |email|
          Java::OrgDspaceEperson::EPerson.findByEmail(self.class.kernel.context, email)
        end
        epeople = users.reject(&:nil?)

        create_workflow_tasks(epeople)
      end

      def add_task_pool_user(email)
        add_task_pool_users([email])
      end

      private

      def update_state
        statement = self.class.update_statement
        self.class.update_query(statement, @state, id)
      end
    end
  end
end
