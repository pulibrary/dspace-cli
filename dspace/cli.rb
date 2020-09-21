# frozen_string_literal: true

module DSpace
  module CLI
    autoload(:MetadataField, 'metadata_field')
    autoload(:Metadatum, 'metadatum')

    autoload(:Item, 'item')
    autoload(:Collection, 'collection')
    autoload(:Community, 'community')

    autoload(:SeniorThesisItem, 'senior_thesis_item')
    autoload(:SeniorThesisCollection, 'senior_thesis_collection')
    autoload(:SeniorThesisCommunity, 'senior_thesis_community')
  end
end

require 'cli/senior_thesis_community'
