class Submission
  attr_reader :id, :department

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

