module DSpace
  module CLI
    class BatchUpdateTitleJob
      java_import org.dspace.eperson.EPerson

      def self.kernel
        ::DSpace
      end

      def self.build_logger
        logger = Logger.new(STDOUT)
        logger.level = Logger::INFO
        logger
      end

      def initialize(item_ids, title, submission_id)
        @item_ids = item_ids
        @title = title
        @submission_id = submission_id
        @logger = self.class.build_logger
      end

      def items
        @item_ids.map do |item_id|
          SeniorThesisItem.find(item_id.to_i)
        end
      end

      def perform
        items.each do |item|
          @logger.info("Updating the Item #{item.id} title to #{@title}...")
          item.title = @title
          item.submission_id = @submission_id
          item.update
          item.remove_duplicated_metadata
        end
      end
    end
  end
end
