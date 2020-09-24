
module DSpace
  module CLI
    module Jobs

      class BatchUpdate

        def initialize(updates: [])
          @updates = updates
        end

        def to_a
          @updates.to_a
        end

        def each(&block)
          to_a.each(&block)
        end
      end
    end
  end
end
