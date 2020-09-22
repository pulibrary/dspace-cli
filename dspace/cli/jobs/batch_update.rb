
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

        def each
          to_enum(:to_a)
        end
      end
    end
  end
end
