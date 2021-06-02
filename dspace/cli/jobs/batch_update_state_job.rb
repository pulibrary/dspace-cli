# frozen_string_literal: true

module DSpace
  module CLI
    module Jobs
      # Job for updating the workflow state for a set of Items
      class BatchUpdateStateJob
        java_import org.dspace.eperson.EPerson
        java_import(org.dspace.workflow.WorkflowManager)

        def self.kernel
          ::DSpace
        end

        def self.build_logger
          logger = Logger.new($stdout)
          logger.level = Logger::INFO
          logger
        end

        def initialize(item_ids, state, eperson_email)
          @item_ids = item_ids
          @state = if state == 'ARCHIVED'
                     Java::OrgDspaceWorkflow::WorkflowManager::WFSTATE_ARCHIVE # This is a hack for the Item#advance_workflow method
                   else
                     state.to_i
                   end
          @eperson_email = eperson_email
          @logger = self.class.build_logger
        end

        def items
          @item_ids.map do |item_id|
            SeniorThesisItem.find(item_id.to_i)
          end
        end

        def eperson
          Java::OrgDspaceEperson::EPerson.findByEmail(self.class.kernel.context, @eperson_email)
        end

        def perform
          items.each do |item|
            @logger.info("Advancing Item #{item.id} to the state #{@state} for the user #{eperson.getEmail}...")
            item.advance_workflow_to_state(eperson, @state)
            item.update
          end
        end
      end
    end
  end
end
