module DSpace
  # Classes specific to command-line operations
  module CLI
    module OpenAccessRepository
      autoload(:Item, File.join(File.dirname(__FILE__), 'open_access_repository', 'item'))
      autoload(:Collection, File.join(File.dirname(__FILE__), 'open_access_repository', 'collection'))
      autoload(:Query, File.join(File.dirname(__FILE__), 'open_access_repository', 'query'))
    end
  end
end
