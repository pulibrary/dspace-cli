
module DSpace
  module CLI
    module Jobs
    class UpdateHandleJob

      def self.build_logger
        logger = Logger.new(STDOUT)
        logger.level = Logger::INFO
        logger
      end

      def initialize(item_id, handle)
        @item_id = item_id
        @handle = handle
        @logger = self.class.build_logger
      end

      def self.item_class
        Item
      end

      def item
        self.class.item_class.find(item_id.to_i)
      end

      def perform
        item.handle = handle
        item.update
      end
    end
  end
  end
end
