# UNFINISHED
# 
# This script appears like it was left in the middle of debugging. All functionality
# has been commented out and replaced with print statements.

require 'cli'

DSpace.load
DSpace.login 'monikam'

dept = 'Creative Writing Program'
dept = 'Aeronautical Engineering'
dept = 'Theater'

def del_bad_department(dept)
  items = DSpace.findByMetadataValue('pu.department',  dept, 2)
  for i in items do
     if not i.getOwningCollection.getName.start_with? dept then
       shortName = i.getOwningCollection.getName.split(',')[0]
       if shortName.start_with? 'Neuro' then
         puts ['NEURO', i.getHandle, shortName, i.getOwningCollection.getName].join  "\t"
       else
         puts ['DELETE', i.getHandle, shortName, i.getOwningCollection.getName, i.getMetadataFirstValue('pu', 'certificate', nil, '*')].join  "\t"
         #i.clearMetadata('pu', 'department', nil, '*')
         #i.update
       end
     end
  end
end

del_bad_department dept
