# frozen_string_literal: true

module DSpace
  module CLI
    module Jobs
      # Job for exporting ResourcePolicy metadata for an Item
      class ExportPoliciesJob
        def self.build_logger
          logger = Logger.new($stdout)
          logger.level = Logger::INFO
          logger
        end

        def initialize(dspace_object:, file_path:)
          @dspace_object = dspace_object
          @file_path = file_path
          @logger = self.class.build_logger
        end

        # just the arks and embargo dates associated with the resource metadata, and the bitstreams in production
        def self.default_headers
          %w[
            bitstream_id
            bitstream_name
            bundle_id
            bundle_name
            item_id
            item_handle
            item_state
            item_title
            item_author
            item_collection
          ]
        end

        def self.resource_policy_headers
          %w[
            policy_id
            policy_action
            policy_eperson
            policy_group
            policy_start_date
            policy_end_date
            policy_name
            policy_type
            policy_description
          ]
        end

        def bundles
          @dspace_object.bundles
        end

        def bundle_metadata
          children = bundles.map(&:metadata)
          children.flatten
        end

        def bundle_metadata_fields
          children = bundle_metadata.map(&:metadata_field)
          children.flatten
        end

        def bitstreams
          children = bundles.map(&:bitstreams)
          children.flatten
        end

        def bitstream_metadata
          children = bitstreams.map(&:metadata)
          children.flatten
        end

        def bitstream_metadata_fields
          values = bitstream_metadata.map(&:metadata_field)
          values.uniq(&:to_s)
        end

        def metadata_fields
          values = bundle_metadata_fields + bitstream_metadata_fields
          values.uniq(&:to_s)
        end

        def resource_policies
          bundle_children = bundles.map(&:resource_policies)
          children = bundle_children.flatten

          bitstream_children = bitstreams.map(&:resource_policies)
          children + bitstream_children.flatten
        end

        def headers
          values = self.class.default_headers
          values += self.class.resource_policy_headers

          metadata_fields.each do |metadata_field|
            values << metadata_field.to_s
          end

          values
        end

        def build_csv_row(policy)
          row = []
          row << policy.resource.id
          row << policy.resource.name
          if policy.resource.respond_to?(:bundle)
            row << policy.resource.bundle.id
            row << policy.resource.bundle.name
          else
            row << ''
            row << ''
          end
          row << @dspace_object.id
          row << @dspace_object.handle
          row << @dspace_object.state
          row << @dspace_object.title
          row << @dspace_object.author
          row << @dspace_object.first_collection_title

          row << policy.id
          row << policy.action_text
          row << policy.eperson_email
          row << policy.group_name
          row << policy.start_date
          row << policy.end_date
          row << policy.name
          row << policy.type
          row << policy.description

          metadata_values = {}
          policy.resource.metadata.each do |metadatum|
            key = metadatum.metadata_field.to_s
            metadata_value = metadata_values.fetch(key, [])

            metadata_value << metadatum.value.gsub(/\R/, '')

            metadata_values[key] = metadata_value
          end

          metadata_values.each_value do |value|
            row << value.join(';')
          end

          row
        end

        def build_existing_file
          File.new(@file_path, 'r:UTF-8')
        end

        def existing_csv_table
          return if File.empty?(@file_path)

          existing_file = build_existing_file
          CSV.parse(existing_file, headers: true)
        end

        def existing_rows
          existing_csv_table.to_a
        end

        def existing_headers
          return [] if existing_csv_table.nil?

          existing_csv_table.headers
        end

        def csv_rows
          rows = []
          rows << headers if File.empty?(@file_path)

          resource_policies.each do |policy|
            rows << build_csv_row(policy)
          end

          rows
        end

        def build_csv
          CSV.generate do |csv|
            csv_rows.each do |row|
              csv << row
            end
          end
        end

        def csv
          @csv ||= build_csv
        end

        def output_file
          @output_file ||= File.new(@file_path, 'a:UTF-8')
        end

        def write
          output_file.write(csv.to_s)
          output_file.close
        end

        def perform(**_args)
          @logger.info("Exporting the metadata from #{@dspace_object.id} to #{@file_path}...")
          write
        end
      end
    end
  end
end
