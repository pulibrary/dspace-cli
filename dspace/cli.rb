# frozen_string_literal: true

require 'pry-debugger-jruby'

module DSpace
  module CLI
    autoload(:DSpaceObject, File.join(File.dirname(__FILE__), 'cli', 'dspace_object'))

    autoload(:Metadatum, File.join(File.dirname(__FILE__), 'cli', 'metadatum'))
    autoload(:MetadataField, File.join(File.dirname(__FILE__), 'cli', 'metadata_field'))

    autoload(:ExportJob, File.join(File.dirname(__FILE__), 'cli', 'export_job'))

    autoload(:BrowseIndex, File.join(File.dirname(__FILE__), 'cli', 'browse_index'))

    autoload(:WorkflowItem, File.join(File.dirname(__FILE__), 'cli', 'workflow_item'))

    autoload(:Item, File.join(File.dirname(__FILE__), 'cli', 'item'))
    autoload(:Community, File.join(File.dirname(__FILE__), 'cli', 'community'))
    autoload(:Collection, File.join(File.dirname(__FILE__), 'cli', 'collection'))

    autoload(:Jobs, File.join(File.dirname(__FILE__), 'cli', 'jobs'))

    autoload(:ResultSet, File.join(File.dirname(__FILE__), 'cli', 'result_set'))
    autoload(:Query, File.join(File.dirname(__FILE__), 'cli', 'query'))

    autoload(:SeniorThesisQuery, File.join(File.dirname(__FILE__), 'cli', 'senior_thesis_query'))
    autoload(:SeniorThesisItem, File.join(File.dirname(__FILE__), 'cli', 'senior_thesis_item'))
    autoload(:SeniorThesisCollection, File.join(File.dirname(__FILE__), 'cli', 'senior_thesis_collection'))
    autoload(:SeniorThesisCommunity, File.join(File.dirname(__FILE__), 'cli', 'senior_thesis_community'))

    autoload(:DCollection, File.join(File.dirname(__FILE__), 'cli', 'legacy', 'dcollection'))

    autoload(:SerialsCollection, File.join(File.dirname(__FILE__), 'cli', 'serials_collection'))
    autoload(:PublicSerialsCollection, File.join(File.dirname(__FILE__), 'cli', 'public_serials_collection'))
    autoload(:PrivateSerialsCollection, File.join(File.dirname(__FILE__), 'cli', 'private_serials_collection'))

  end
end
