module DSpace
  module CLI
    class PublicSerialsCollection < SerialsCollection
      def self.community
        kernel.fromString(public_community_handle)
      end
    end
  end
end
