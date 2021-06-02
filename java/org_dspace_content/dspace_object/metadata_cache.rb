# frozen_string_literal: true

module Java
  module OrgDspaceContent
    module DSpaceObject
      class MetadataCache
        attr_reader :metadata

        def initialize(metadata)
          @metadata = metadata
        end
      end
    end
  end
end
