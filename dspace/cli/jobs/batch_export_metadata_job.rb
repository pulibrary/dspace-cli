module DSpace
  module CLI
    module Jobs
      class BatchExportMetadataJob < BatchJob
        def self.child_job_class
          ExportMetadataJob
        end

        def self.build(file_path:, dspace_objects: [], **job_args)
          jobs = []

          dspace_objects.each do |object|
            jobs << child_job_class.new(dspace_object: object, file_path: file_path)
          end
=begin
        def initialize(dspace_object:, file_path:)
          @dspace_object = dspace_object
          @file_path = file_path
          @logger = self.class.build_logger
        end

=end
          new(child_jobs: jobs, **job_args)
        end
      end
    end
  end
end
