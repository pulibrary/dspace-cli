# frozen_string_literal: true

module DSpace
  module CLI
    # Class modeling a Serials Collection with access-restricted members
    class PublicSerialsCollection < SerialsCollection
      def self.community
        kernel.fromString(public_community_handle)
      end
    end
  end
end
