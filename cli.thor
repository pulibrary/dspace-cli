ROOT_PATH = File.dirname(__FILE__)

require File.join(ROOT_PATH, 'dspace')

class Dataspace < Thor
  desc "import_metadata", "DO NOT"
  method_option :file, type: :string, aliases: 'f'
  method_option :primary_column, type: :string, aliases: 'k'

  def import_metadata
    import_file_path = options[:file]
    primary_column = options[:primary_column]

    update = DSpace::CLI::Jobs::CSVUpdate.build_from_file(path: import_file_path, primary_column: primary_column)
    update.update_metadata
  end
end
