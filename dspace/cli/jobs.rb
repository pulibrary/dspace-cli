# frozen_string_literal: true

module DSpace
  module CLI
    # Classes modeling synchronous or asynchronous jobs
    module Jobs
      autoload(:Update, File.join(File.dirname(__FILE__), 'jobs', 'update'))
      autoload(:BatchUpdate, File.join(File.dirname(__FILE__), 'jobs', 'batch_update'))
      autoload(:FileUpdate, File.join(File.dirname(__FILE__), 'jobs', 'file_update'))
      autoload(:CSVUpdate, File.join(File.dirname(__FILE__), 'jobs', 'csv_update'))

      autoload(:Job, File.join(File.dirname(__FILE__), 'jobs', 'job'))
      autoload(:BatchJob, File.join(File.dirname(__FILE__), 'jobs', 'batch_job'))
      autoload(:BatchImportJob, File.join(File.dirname(__FILE__), 'jobs', 'batch_import_job'))

      autoload(:ExportMetadataJob, File.join(File.dirname(__FILE__), 'jobs', 'export_metadata_job'))
      autoload(:BatchExportMetadataJob, File.join(File.dirname(__FILE__), 'jobs', 'batch_export_metadata_job'))

      autoload(:ExportPoliciesJob, File.join(File.dirname(__FILE__), 'jobs', 'export_policies_job'))
      autoload(:BatchExportPoliciesJob, File.join(File.dirname(__FILE__), 'jobs', 'batch_export_policies_job'))

      autoload(:BatchUpdateStateJob, File.join(File.dirname(__FILE__), 'jobs', 'batch_update_state_job'))

      autoload(:UpdateHandleJob, File.join(File.dirname(__FILE__), 'jobs', 'update_handle_job'))
      autoload(:BatchUpdateHandleJob, File.join(File.dirname(__FILE__), 'jobs', 'batch_update_handle_job'))

      autoload(:BatchUpdateMetadataJob, File.join(File.dirname(__FILE__), 'jobs', 'batch_update_metadata_job'))

      autoload(:BitstreamExportJob, File.join(File.dirname(__FILE__), 'cli', 'bitstream_export_job'))
    end
  end
end
