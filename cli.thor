# frozen_string_literal: true

require File.join(File.dirname(__FILE__), 'dspace')

# Thor CLI tasks for general DSpace Item management
class Dspace < Thor
  desc 'import_metadata', 'Import Item metadata from a CSV file'
  method_option :file, type: :string, aliases: 'f'
  method_option :primary_column, type: :string, aliases: 'k'

  def import_metadata
    import_file_path = options[:file]
    primary_column = options[:primary_column]

    update = DSpace::CLI::Jobs::CSVUpdate.build_from_file(path: import_file_path, primary_column: primary_column)
    update.update_metadata
  end

  desc 'update_handles', 'Import the handles from a CSV'
  method_option :file, type: :string, aliases: 'f'
  method_option :primary_column, type: :string, aliases: 'k'
  def update_handles
    csv_file_path = options[:file]
    primary_column = options[:primary_column]

    job = DSpace::CLI::Jobs::BatchUpdateHandleJob.build_from_csv(file_path: csv_file_path, primary_column: primary_column)
    job.perform
  end
end

class Dataspace < Thor
  def self.exit_on_failure?
    true
  end

  # Thor CLI tasks for Senior Thesis Item management
  class SeniorTheses < Thor
    desc 'batch_advance_workflow', 'Advances the WorkflowItem state for Department Items which have been imported'
    method_option :user, type: :string, aliases: 'u'
    method_option :year, type: :string, aliases: 'y'
    method_option :department, type: :string, aliases: 'd'
    method_option :editor, type: :string, aliases: 'e'

    def batch_advance_workflow
      user = options[:user]
      DSpace.load
      DSpace.login(user)

      year = options[:year]
      query = DSpace::CLI::SeniorThesisCommunity.find_by_class_year(year)
      raise(StandardError, "Unable to find any Items for the academic year #{year}") if query.results.empty?
      shell.say_status(:ok, "Found #{query.results.length} Items for the academic year #{year}", :green)

      department = options[:department]
      sub_query = query.find_by_department(department)
      raise(StandardError, "Unable to find any Items for the department #{department}") if sub_query.results.empty?
      shell.say_status(:ok, "Found #{sub_query.results.length} Items for the department #{department}", :green)

      pending = sub_query.results.reject { |i| i.workflow_item.nil? }.select { |i| i.workflow_item.state < Java::OrgDspaceWorkflow::WorkflowManager::WFSTATE_STEP3POOL }
      shell.say_status(:ok, "Found #{pending.length} Items which need to be advanced to the pending editorial review workflow state", :green)
      raise(StandardError, "Unable to find any Items which need to have the WorkflowItem state advanced") if pending.empty?

      editor_email = options[:editor]
      editor = Java::OrgDspaceEperson::EPerson.findByEmail(DSpace.context, editor_email)
      raise(StandardError, "Unable to find any DSpace EPerson for the editor e-mail #{editor_email}") if editor.nil?
      workflow_items = Java::OrgDspaceWorkflow::WorkflowManager.getPooledTasks(DSpace.context, editor)
      pool_items = workflow_items.to_a.map { |wfi| wfi.getItem }
      existing_workflow_ids = pool_items.map { |item| item.getID }

      pending.each do |pending_item|
        initial_state = pending_item.workflow_item.state
	last_state = Java::OrgDspaceWorkflow::WorkflowManager::WFSTATE_STEP3POOL - 1

        shell.say_status(:ok, "Initial state of #{pending_item.id} is #{initial_state}", :green)
	
        (initial_state..last_state).each do |state|
	  new_state = state + 1
          shell.say_status(:ok, "Advancing the WorkflowItem state for #{pending_item.id} to the state #{new_state}", :green)
          pending_item.set_workflow_with_submitter(new_state: new_state)
          DSpace.commit
          pending_item.reload
          shell.say_status(:ok, "Advanced the WorkflowItem state for #{pending_item.id} to the state #{pending_item.workflow_item.state}", :green)
        end
        
        shell.say_status(:ok, "Final state of #{pending_item.id} is #{pending_item.workflow_item.state}", :green)
	next if existing_workflow_ids.include? pending_item.id # Do not add to the task pool if the item is already in the task pool
        pending_item.add_task_pool_user(editor_email)
        shell.say_status(:ok, "Added the Task Pool entry for user #{editor_email}", :green)
      end
    end

    desc 'export_metadata', 'Export Item metadata to a CSV file'
    method_option :file, type: :string, aliases: 'f'
    method_option :class_year, type: :string, aliases: 'y'
    method_option :department, type: :string, aliases: 'd'
    method_option :certificate_program, type: :string, aliases: 'p'
    def export_metadata
      namespace 'senior_theses'

      export_file_path = options[:file]
      class_year = options[:class_year]
      department = options[:department]
      certificate_program = options[:certificate_program]

      query = DSpace::CLI::SeniorThesisQuery.new
      query.find_by_class_year(class_year) unless class_year.nil?
      query = query.find_by_department(department) unless department.nil?
      query = query.find_by_certificate_program(certificate_program) unless certificate_program.nil?
      query.result_set.export_metadata_to_file(csv_file_path: export_file_path)
    end

    desc 'export_community_metadata', 'Export Community Item metadata to CSV files'
    method_option :class_year, type: :string, aliases: 'y'
    def export_community_metadata
      namespace 'senior_theses'

      class_year = options[:class_year]

      DSpace::CLI::SeniorThesisCommunity.certificate_program_titles.each do |certificate_program|
        segment = certificate_program.downcase.gsub(/\s/, '_')
        export_file_path = "#{segment}.csv"

        query = DSpace::CLI::SeniorThesisQuery.new
        query.find_by_class_year(class_year) unless class_year.nil?
        query = query.find_by_certificate_program(certificate_program) unless certificate_program.nil?
        query.result_set.export_metadata_to_file(csv_file_path: export_file_path)
      end

      DSpace::CLI::SeniorThesisCommunity.collection_titles.each do |department|
        segment = department.downcase.gsub(/\s/, '_')
        export_file_path = "#{segment}.csv"

        query = DSpace::CLI::SeniorThesisQuery.new
        query.find_by_class_year(class_year) unless class_year.nil?
        query = query.find_by_department(department) unless department.nil?
        query.result_set.export_metadata_to_file(csv_file_path: export_file_path)
      end
    end

    desc 'export_policies', 'Export Bitstream policy metadata to a CSV file'
    method_option :file, type: :string, aliases: 'f'
    method_option :class_year, type: :string, aliases: 'y'
    method_option :department, type: :string, aliases: 'd'
    method_option :certificate_program, type: :string, aliases: 'p'
    def export_policies
      namespace 'senior_theses'

      export_file_path = options[:file]
      class_year = options[:class_year]
      department = options[:department]
      certificate_program = options[:certificate_program]

      query = DSpace::CLI::SeniorThesisQuery.new
      query.find_by_class_year(class_year) unless class_year.nil?
      query = query.find_by_department(department) unless department.nil?
      query = query.find_by_certificate_program(certificate_program) unless certificate_program.nil?
      query.result_set.export_policies_to_file(csv_file_path: export_file_path)
    end

    desc 'export_community_policies', 'Export Bitstream policy metadata for all Items in the Community to a CSV file'
    method_option :class_year, type: :string, aliases: 'y'
    def export_community_policies
      namespace 'senior_theses'

      class_year = options[:class_year]

      DSpace::CLI::SeniorThesisCommunity.certificate_program_titles.each do |certificate_program|
        segment = certificate_program.downcase.gsub(/\s/, '_')
        export_file_path = "#{segment}.csv"

        query = DSpace::CLI::SeniorThesisQuery.new
        query.find_by_class_year(class_year) unless class_year.nil?
        query = query.find_by_certificate_program(certificate_program) unless certificate_program.nil?
        query.result_set.export_policies_to_file(csv_file_path: export_file_path)
      end

      DSpace::CLI::SeniorThesisCommunity.collection_titles.each do |department|
        segment = department.downcase.gsub(/\s/, '_')
        export_file_path = "#{segment}.csv"

        query = DSpace::CLI::SeniorThesisQuery.new
        query.find_by_class_year(class_year) unless class_year.nil?
        query = query.find_by_department(department) unless department.nil?
        query.result_set.export_policies_to_file(csv_file_path: export_file_path)
      end
    end
  end
end
