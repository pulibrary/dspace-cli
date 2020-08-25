ROOT_PATH = File.dirname(__FILE__)

# require File.join(ROOT_PATH, 'cli', 'dspace')
# require File.join(ROOT_PATH, 'cli', 'ditem')
# require File.join(ROOT_PATH, 'cli', 'dcollection')
# require File.join(ROOT_PATH, 'cli', 'dcommunity')
require File.join(ROOT_PATH, 'cli', 'submission')

require 'pathname'
require 'nokogiri'

class Dspace < Thor
  desc "import", "import a DSpace"
  def import
    # To be implemented
  end

  class Dataspace < Thor
    desc "import_dissertation IMPORT_DIR_PATH", "import a graduate dissertation into DataSpace"
    method_option :import_dir_path, :type => :string
    def import_dissertation
      # To be implemented
    end

    desc "import_senior_thesis", "import a Thesis Central submission into DataSpace"
    method_option :submission_id, :type => :string, aliases: 's'
    def import_senior_thesis
      # To be implemented
    end

    desc "generate_cover_page", "prepends a cover page PDF to a senior thesis submission"
    method_option :submission_id, :type => :string, aliases: 's'
    method_option :department, :type => :string, aliases: 'd'
    def generate_cover_page
      submission_id = options[:submission_id]
      department = options[:department]

      submission = Submission.new(id: submission_id, department: department)
      submission.generate_cover_page
    end

    desc "insert_metadata", "inserts a DSpace metadata field for a senior theses submission"
    method_option :submission_id, :type => :string, aliases: 's'
    method_option :department, :type => :string, aliases: 'd'
    method_option :schema, :type => :string, aliases: 'S'
    method_option :element, :type => :string, aliases: 'e'
    method_option :qualifier, :type => :string, aliases: 'q'
    method_option :value, :type => :string, aliases: 'v'
    def insert_metadata
      submission_id = options[:submission_id]
      department = options[:department]

      schema = options[:schema]
      element = options[:element]
      qualifier = options[:qualifier]
      value = options[:value]

      submission = Submission.new(id: submission_id, department: department)
      submission.insert_metadata(schema: schema, element: element, qualifier: qualifier, value: value)
    end

    no_commands do
      # To be implemented
    end
  end

  no_commands do
    # To be implemented
  end
end
