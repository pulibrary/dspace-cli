# frozen_string_literal: true

module DSpace
  module CLI
    autoload(:Metadatum, File.join(File.dirname(__FILE__), 'cli', 'metadatum'))
    autoload(:MetadataField, File.join(File.dirname(__FILE__), 'cli', 'metadata_field'))

    autoload(:Item, File.join(File.dirname(__FILE__), 'cli', 'item'))
    autoload(:Collection, File.join(File.dirname(__FILE__), 'cli', 'collection'))
    autoload(:Community, File.join(File.dirname(__FILE__), 'cli', 'community'))

    autoload(:SeniorThesisQuery, File.join(File.dirname(__FILE__), 'cli', 'senior_thesis_query'))
    autoload(:SeniorThesisItem, File.join(File.dirname(__FILE__), 'cli', 'senior_thesis_item'))
    autoload(:SeniorThesisCollection, File.join(File.dirname(__FILE__), 'cli', 'senior_thesis_collection'))
    autoload(:SeniorThesisCommunity, File.join(File.dirname(__FILE__), 'cli', 'senior_thesis_community'))
  end
end
