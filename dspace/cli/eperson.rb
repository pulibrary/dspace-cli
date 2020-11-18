# frozen_string_literal: true

module DSpace
  module CLI
    # Models the EPerson Java API Class
    class EPerson
      java_import(org.dspace.core.Constants)
      java_import(org.dspace.workflow.WorkflowItem)
      java_import(org.dspace.eperson.EPerson)

      attr_reader :model

      def self.kernel
        ::DSpace
      end

      def self.model_class
        org.dspace.eperson.EPerson
      end

      def initialize(model)
        @model = model
      end

      def id
        @model.getID
      end

      def language
        @model.getLanguage
      end

      def handle
        @model.getHandle
      end

      def email
        @model.getEmail
      end

      def net_id
        @model.getNetid
      end

      def first_name
        @model.getFirstName
      end

      def last_name
        @model.getLastName
      end

      def workflow_items
        workflow_item_class.find_by_submitter(self)
      end

      def self.find_by_email(email)
        model = model_class.findByEmail(kernel.context, email)
        return if model.nil?

        new(model)
      end
    end
  end
end
