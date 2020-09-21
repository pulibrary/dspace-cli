# frozen_string_literal: true

module DSpace
  module CLI
    autoload(:DSpaceObject, File.join(File.dirname(__FILE__), 'cli', 'dspace_object'))

    autoload(:Metadatum, File.join(File.dirname(__FILE__), 'cli', 'metadatum'))
    autoload(:MetadataField, File.join(File.dirname(__FILE__), 'cli', 'metadata_field'))

    autoload(:ExportJob, File.join(File.dirname(__FILE__), 'cli', 'export_job'))

    autoload(:BrowseIndex, File.join(File.dirname(__FILE__), 'cli', 'browse_index'))

    autoload(:Item, File.join(File.dirname(__FILE__), 'cli', 'item'))
    autoload(:Collection, File.join(File.dirname(__FILE__), 'cli', 'collection'))
    autoload(:Community, File.join(File.dirname(__FILE__), 'cli', 'community'))

    autoload(:Query, File.join(File.dirname(__FILE__), 'cli', 'query'))

    autoload(:SeniorThesisQuery, File.join(File.dirname(__FILE__), 'cli', 'senior_thesis_query'))
    autoload(:SeniorThesisItem, File.join(File.dirname(__FILE__), 'cli', 'senior_thesis_item'))
    autoload(:SeniorThesisCollection, File.join(File.dirname(__FILE__), 'cli', 'senior_thesis_collection'))
    autoload(:SeniorThesisCommunity, File.join(File.dirname(__FILE__), 'cli', 'senior_thesis_community'))
  end
end
