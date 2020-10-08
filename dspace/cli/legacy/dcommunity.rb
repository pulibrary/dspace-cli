##
#
module DSpace
  module CLI
    class DCommunity < ::DCommunity
      # get Collection from within DCommunity by name
      # QUESTION: Is this the appropriate way to get match? I guess zero-eth index
      #   of an empty list is nil, and names are unique?
      #
      # @param name [String]
      def find_collection_by_name(name)
        @obj.getCollections.select { |c| c.getName == name }[0]
      end

      # Search for the collection within this DCommunity, and if it doesn't exist,
      #   create an empty Collection.
      # QUESTION: Is this "find_or_create" convention common in ruby? Separating out
      #   functionality is usually preferable in other languages I've encountered.
      #
      # @param name [String]
      def find_or_create_collection_by_name(name)
        col = find_collection_by_name(name)

        if col.nil?
          col = @obj.createCollection

          # TODO: Look up this function
          col.setMetadataSingleValue('dc', 'title', nil, nil, name)
          col.update
        end

        col
      end

      # apply standardized naming convention to all Collections within Community
      def name_workflow_groups
        @obj.getCollections.each { |col| DSpace.create(col).name_workflow_groups }
        self
      end

      def name_submitter_group
        @obj.getCollections.each { |col| DSpace.create(col).name_submitter_group }
        self
      end

      def find_or_create_workflow_group(step)
        @obj.getCollections.collect { |col| DSpace.create(col).find_or_create_workflow_group(step) }
      end

      # Get all bitstreams within Community
      def bitstreams(bundleName = 'ORIGINAL')
        bits = []
        @obj.getCollections.each do |col|
          bits += DSpace.create(col).bitstreams(bundleName)
        end
        bits
      end
    end
  end
end
