# frozen_string_literal: true

module DSpace
  module CLI
    # Class modeling a Serials Collection with access-restricted members
    class PrivateSerialsCollection < SerialsCollection
      def self.community
        kernel.fromString(private_community_handle)
      end
    end
  end
end
