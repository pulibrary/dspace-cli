require 'cli'
require 'setup'

DSpace.load
DSpace.login 'monikam'

dept = 'Creative Writing Program'
dept = 'Theater'
dept = 'Aeronautical Engineering'

def del_bad_department(dept)
  items = DSpace.findByMetadataValue('pu.department',  dept, 2)
  for i in items do
     if not i.getOwningCollection.getName.start_with? dept then
       shortName = i.getOwningCollection.getName.split(',')[0]
       if (shortName == 'Creative Writing Program') then
        puts [i.getID, i.getHandle, i.getMetadataFirstValue('pu', 'date', 'classyear', '*'),
              shortName, i.getOwningCollection.getName,
              i.getMetadataFirstValue('pu', 'department', nil, '*'),
              i.getMetadataFirstValue('pu', 'certificate', nil, '*')].join  "\t"
        i.clearMetadata('pu', 'department', nil, '*')
        i.update
       end

     end
  end
  return items
end


def fix_bad_department(dept)
  items = DSpace.findByMetadataValue('pu.department',  dept, 2)
  for i in items do
    if not i.getOwningCollection.getName.start_with? dept then
      shortName = i.getOwningCollection.getName.split(',')[0]
      if (shortName != 'Creative Writing Program' ) then
        puts [i.getID, i.getHandle, i.getMetadataFirstValue('pu', 'date', 'classyear', '*'),
              'desired= ' + shortName, 'col-name=' + i.getOwningCollection.getName,
              'pu.deprtment=' + i.getMetadataFirstValue('pu', 'department', nil, '*')
              ].join  "\t"
        i.setMetadataSingleValue('pu', 'department', nil, '*', shortName)
        i.update
      end

    end
  end
  return items
end


del_bad_department_department dept
fix_bad_department dept
#DSpace.commit

