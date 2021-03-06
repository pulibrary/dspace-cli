# frozen_string_literal: true

module DSpace
  module CLI
    module Jobs
      # Job for updating the handle for a given DSpace Item
      class UpdateHandleJob < Job
        def initialize(id:, handle:, **args)
          super(**args)
          @item_id = id
          @handle = handle
        end

        def item
          self.class.item_class.find(@item_id.to_i)
        end

        def perform(**_args)
          return if @handle.nil?

          @logger.info("Updating the handle from #{item.handle} to #{@handle} for #{item.id}...")
          item.handle = @handle
          item.update
          item.reload
          @logger.info("Updated the handle to #{item.handle} for #{item.id}")
        end
      end
    end
  end
end
