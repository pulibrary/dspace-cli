# frozen_string_literal: true

module Metadata
  # Class decorating the DSpace MetadataField Class
  # @see org.dspace.content.MetadataField
  class Field
    attr_reader :schema, :element, :qualifier

    def initialize(schema, element, qualifier = nil)
      @schema = schema
      @element = element
      @qualifier = qualifier
    end

    def to_s
      if qualifier.nil?
        "#{schema}.#{element}"
      else
        "#{schema}.#{element}.#{qualifier}"
      end
    end
  end
end
