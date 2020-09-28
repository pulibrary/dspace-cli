module DSpace
  module CLI
    class PrivateSerialsCollection < SerialsCollection
      def self.community
        kernel.fromString(private_community_handle)
      end
    end
  end
end
