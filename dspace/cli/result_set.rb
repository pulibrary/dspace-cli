module DSpace
  module CLI
    class ResultSet
      java_import(org.dspace.content.Collection)
      java_import(org.dspace.eperson.EPerson)

      attr_reader :members

      def self.kernel
        ::DSpace
      end

      def initialize(members)
        @members = members
      end

      def update
        members.each { |member| member.update }
      end

      def self.collection_class
        DSpace::CLI::Collection
      end

      # This isn't really specific to a ResultSet
      # This should be moved to Update
      def update_handles_from_file(csv_file_path:)
        job = DSpace::CLI::Jobs::BatchUpdateHandleJob.build_from_csv(file_path: csv_file_path)
        job.perform
      end

      def export_metadata_to_file(csv_file_path:)

        if !File.exists?(csv_file_path)
          value = File.join(File.dirname(__FILE__), '..', '..', 'exports', 'metadata', csv_file_path)
        else
          value = csv_file_path
        end
        absolute_file_path = Pathname.new(value)

        job = DSpace::CLI::Jobs::BatchExportMetadataJob.build(file_path: absolute_file_path, dspace_objects: members)
        job.perform
      end

      def add_to_collection(handle)
        obj = Java::OrgDspaceHandle::HandleManager.resolveToObject(self.class.kernel.context, handle)
        return if obj.nil?

        collection = collection_class.new(obj)

        members.each do |member|
          collection.addItem(member)
        end
        collection.update
      end

      def remove_from_collection(handle)
        obj = Java::OrgDspaceHandle::HandleManager.resolveToObject(self.class.kernel.context, handle)
        return if obj.nil?

        collection = collection_class.new(obj)

        members.each do |member|
          collection.removeItem(member)
        end
        collection.update
      end

      def add_task_pool_users(emails)
        members.each do |member|
          member.add_task_pool_users(emails)
          self.class.kernel.commit
        end
      end

      def add_task_pool_user(email)
        add_task_pool_users([email])
      end

      def remove_task_pool_users(emails)
        members.each do |member|
          member.remove_task_pool_users(emails)
          self.class.kernel.commit
        end
      end

      def remove_task_pool_user(email)
        remove_task_pool_users([email])
      end

      def move_collection(from_handle, to_handle, inherit_default_policies = false)
        members.each do |member|
          member.move_collection_by_handles(from_handle, to_handle, inherit_default_policies)
          self.class.kernel.commit
        end
      end

      def self.normalize_department_title(title)
        normal_title = title.downcase
        normal_title.gsub(/\s/, '_')
      end

      def submitter=(eperson)
        members.each do |member|
          member.submitter = eperson
          member.update
        end
        self.class.kernel.commit
      end

      def submitter_email=(email)
        eperson = Java::OrgDspaceEperson::EPerson.findByEmail(self.class.kernel.context, email)
        self.submitter = eperson
      end
    end
  end
end
