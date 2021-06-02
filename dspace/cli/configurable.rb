# frozen_string_literal: true

require 'ostruct'
require 'yaml'

module DSpace
  module CLI
    # DSpace CLI configuration values (parsed from a YAML file)
    class Configuration < OpenStruct
      def bitstream_export_job
        self.class.new(super)
      end

      def jobs
        self.class.new(super)
      end
    end

    # Module providing method mixins for accessing configuration values
    module Configurable
      # rubocop:disable Style/Documentation
      module ClassMethods
        def config_file_path
          value = File.join(File.dirname(__FILE__), '..', '..', 'config', 'dspace.yml')
          Pathname.new(value)
        end

        def config_file
          File.open(config_file_path, 'rb')
        end

        def build_config
          values = YAML.safe_load(config_file.read)
          config_file.close
          CLI::Configuration.new(values)
        end

        def config
          @config ||= build_config
        end
      end
      # rubocop:enable Style/Documentation

      def self.included(klass)
        klass.extend(ClassMethods)
      end
    end
  end
end
