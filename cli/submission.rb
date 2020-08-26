
require 'fileutils'

class Submission
  attr_reader :id, :department

  class CoverPageJob
    def self.root_path
      value = File.dirname(__FILE__)
      File.join(value, '..')
    end

    def self.template_path
      value = File.join(root_path, 'imports', 'senior_theses', 'cover_page_template.pdf')
      Pathname.new(value)
    end

    def self.command(output_file_path:, pdf_file_path:)
      "/usr/bin/env gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite '-sOutputFile=#{output_file_path}' #{pdf_file_path} #{template_path}"
    end

    def initialize(output_file_path:, pdf_file_path:)
      @output_file_path = output_file_path
      @pdf_file_path = pdf_file_path
    end

    def perform
      command = self.class.command(output_file_path: @output_file_path, pdf_file_path: @pdf_file_path)
      `#{command}`
    end
  end

  def submission_pdf_name
    entries = Dir.glob("#{dir_path}/*pdf")
    pdf_entries = entries.reject { |f| f.include?('ORIG-') }
    raise "Could not find a PDF in #{dir_path}" if pdf_entries.empty?

    File.basename(pdf_entries.first)
  end

  def pdf_name
    submission_pdf_name
  end

  def submission_pdf_path
    dir_path.join(submission_pdf_name)
  end

  def original_pdf_name
    "ORIG-#{submission_pdf_name}"
  end

  def original_pdf_path
    dir_path.join(original_pdf_name)
  end

  def cover_page_job
    CoverPageJob.new(output_file_path: submission_pdf_path, pdf_file_path: original_pdf_path)
  end

  def generate_cover_page
    if !File.exist?(original_pdf_path)
      FileUtils.copy_file(submission_pdf_path, original_pdf_path)
    end

    cover_page_job.perform

    self.cover_page = 'SeniorThesisCoverPage'
  end

  def initialize(id:, department:)
    @id = id
    @department = department
  end

  def self.root_path
    value = File.dirname(__FILE__)
    File.join(value, '..')
  end

  def dir_name
    "submission_#{id}"
  end

  def dir_path
    value = File.join(self.class.root_path, 'imports', 'senior_theses', department, dir_name)
    Pathname.new(value)
  end

  def dublin_core_file_path
    dir_path.join('dublin_core.xml')
  end

  def dublin_core_document
    File.open(dublin_core_file_path) { |f| Nokogiri::XML(f) }
  end

  def metadata_pu_file_path
    dir_path.join('metadata_pu.xml')
  end

  def metadata_pu_build_document
    Nokogiri::XML('<dublin_core encoding="utf-8" schema="pu"></dublin_core>')
  end

  def metadata_pu_document
    document = File.open(metadata_pu_file_path) { |f| Nokogiri::XML(f) }
    return document unless document.root.nil?

    metadata_pu_build_document
  end

  def class_year=(value)
    insert_metadata(schema: 'pu', element: 'date', value: value, qualifier: 'classyear')
  end

  def author_id=(value)
    insert_metadata(schema: 'pu', element: 'contributor', value: value, qualifier: 'authorid')
  end

  def cover_page=(value)
    insert_metadata(schema: 'pu', element: 'pdf', value: value, qualifier: 'coverpage')
  end

  def department=(value)
    insert_metadata(schema: 'pu', element: 'department', value: value)
  end

  def certificate=(value)
    insert_metadata(schema: 'pu', element: 'certificate', value: value)
  end

  def insert_metadata(schema:, element:, value:, qualifier: nil)
    element_name = 'dcvalue'
    xpath_base = '//dublin_core'

    document = if schema == 'pu'
                 metadata_pu_document
               else
                 dublin_core_document
               end

    xpath = if qualifier
              "#{xpath_base}/#{element_name}[@element='#{element}' and @qualifier='#{qualifier}']"
            else
              "#{xpath_base}/#{element_name}[@element='#{element}']"
            end

    dom_elements = document.xpath(xpath)
    dom_element = if dom_elements.empty? || dom_elements.length > 1
                    Nokogiri::XML::Node.new(element_name, document)
                  else
                    dom_elements.last
                  end

    dom_element['element'] = element
    dom_element['qualifier'] = qualifier if qualifier
    dom_element.content = value
    document.root.add_child(dom_element)

    file_path = if schema == 'pu'
                  metadata_pu_file_path
                else
                  dublin_core_file_path
                end
    document_file = File.open(file_path, 'wb')
    document.write_xml_to(document_file)
  end
end

