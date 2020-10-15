# frozen_string_literal: true

module DSpace
  module CLI
    class ResourcePolicy
      def self.kernel
        ::DSpace
      end

      def initialize(model)
        @model = model
      end

      def resource_id
        @model.getResourceID
      end

      def resource_type_id
        @model.getResourceType
      end

      def resource_class
        case resource_type_id
        when Core::Constants::BITSTREAM
          Bitstream
        when Core::Constants::BUNDLE
          Bundle
        when Core::Constants::ITEM
          Item
        else
          DSpaceObject
        end
      end

      def resource
        resource_class.find(resource_id)
      end

      def id
        @model.getID
      end

      def action_text
        @model.getActionText
      end

      def eperson_id
        @model.getEPersonID
      end

      def eperson
        eperson_model = @model.getEPerson
        return if eperson_model.nil?

        Core::EPerson.new(eperson_model)
      end

      def eperson_email
        return if eperson.nil?
        eperson.email
      end

      def group_id
        @model.getGroupID
      end

      def group
        group_model = @model.getGroup
        return if group_model.nil?

        Core::Group.new(group_model)
      end

      def group_name
        return if group.nil?
        group.name
      end

      def start_date
        date_value = @model.getStartDate
        return if date_value.nil?

        formatted = date_value.toString
        Date.parse(formatted.to_s)
      end

      def end_date
        date_value = @model.getEndDate
        return if date_value.nil?

        date_value.to_ruby
      end

      def name
        @model.getRpName
      end

      def type
        @model.getRpType
      end

      def description
        @model.getRpDescription
      end
    end
  end
end

