module DSpace
  module CLI
    class SeniorThesisWorkflowItem
      java_import org.dspace.storage.rdbms.DatabaseManager
      java_import org.dspace.eperson.EPerson
      java_import org.dspace.workflow.WorkflowManager
      java_import org.dspace.handle.HandleManager

      attr_reader :obj

      def self.kernel
        ::DSpace
      end

      # This is some internal bug; I am not certain why I cannot use this from DItem
      def initialize(obj)
        @obj = obj
      end

      def id
        @obj.getID
      end

      def update
        @obj.update
        self.class.kernel.commit
        self
      end

      def delete
        @obj.deleteWrapper
        self.class.kernel.commit
        @obj = nil
      end

      def state
        @obj.getState
      end

      def state=(value)
        @obj.setState(value)
      end

      def self.delete_query
        'DELETE FROM tasklistitem WHERE eperson_id = ? AND workflow_id = ?'
      end

      def self.delete_from_database(eperson_id, workflow_id)
        Java::OrgDspaceStorageRdbms::DatabaseManager.updateQuery(kernel.context, delete_query, eperson_id.to_java, workflow_id.to_java)
        kernel.commit
      end

      # magical task pool population
      def create_workflow_tasks(epeople)
        epeople.each do |eperson|
          table_row = Java::OrgDspaceStorageRdbms::DatabaseManager.row('tasklistitem')
          table_row.setColumn('eperson_id', eperson.getID)
          table_row.setColumn('workflow_id', id)
          Java::OrgDspaceStorageRdbms::DatabaseManager.insert(self.class.kernel.context, table_row)

          self.class.kernel.commit

          self.state = Java::OrgDspaceWorkflow::WorkflowManager::WFSTATE_STEP1POOL
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
    end
  end
end
