# frozen_string_literal: true

require 'pry-debugger-jruby'

Dir['/dspace/lib/**/*.jar'].each { |jar_path| require(jar_path) }
require 'dspace'

module DSpace
  autoload(:CLI, File.join(File.dirname(__FILE__), 'dspace', 'cli'))
end
