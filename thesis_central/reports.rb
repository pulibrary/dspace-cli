require 'cli'

DSpace.load

def list_department_info(year)
  items = DSpace.findByMetadataValue('pu.date.classyear', year, nil)
  items.each do |i|
    dept = i.getMetadataByMetadataString('pu.department')[0].value

    puts [i.getID, i.getHandle, i.getMetadataByMetadataString('pu.department')[0].value].join "\t"
  end
end

def wf_list(cur_year)
  wfs = DWorkflowItem.findAll nil
  wfs.each do |w|
    i = w.getItem
    deps = i.getMetadataByMetadataString('pu.department')
    if (deps.length > 0) then
      year = i.getMetadataByMetadataString('pu.date.classyear')[0].value
      if (year.to_i == cur_year) then
        puts [i.getID, year, w.getCollection.getName, i.getMetadataByMetadataString('pu.department')[0].value].join "\t"
        #i.setMetadataSingleValue('pu', 'department', nil, 'en_US', 'Spanish and Portuguese')
        #i.update
      end
    end
  end
end

def walkins()
  items = DSpace.findByMetadataValue('pu.mudd.walkin', 'yes', nil)
  items.each do |i|
    embargo = i.getMetadataByMetadataString('pu.embargo.lift')
    dept = i.getMetadataByMetadataString('pu.department')[0].value
    if embargo.length > 0 and embargo[0].value.start_with? "2017" then
      puts [i.getID, i.getHandle, embargo, dept, i.getName].join "\t"
    end

  end
end