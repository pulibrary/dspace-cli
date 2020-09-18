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

      def add_to_collection(handle)
        obj = Java::OrgDspaceHandle::HandleManager.resolveToObject(self.class.kernel.context, handle)
        return if obj.nil?

        collection = SeniorThesisCollection.new(obj)

        members.each do |member|
          collection.addItem(member)
        end
        collection.update
      end

      def remove_from_collection(handle)
        obj = Java::OrgDspaceHandle::HandleManager.resolveToObject(self.class.kernel.context, handle)
        return if obj.nil?

        collection = SeniorThesisCollection.new(obj)

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

      def item_state_report(output_file_name)
        output_file_path = File.join(ItemStateReport.root_path, output_file_name)

        ItemStateReport.new(members, output_file_path)
      end

      def item_author_report(output_file_name)
        output_file_path = File.join(ItemAuthorReport.root_path, output_file_name)

        ItemAuthorReport.new(members, output_file_path)
      end

      def item_certificate_program_report(output_file_name)
        output_file_path = File.join(ItemCertificateProgramReport.root_path, output_file_name)

        ItemCertificateProgramReport.new(members, output_file_path)
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
