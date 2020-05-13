# UNFINISHED
#
# This script appears like it was abandoned mid-development.

require 'cli/dspace.rb'
DSpace.load

#DSpace.login 'monikam'


def clean_submitters_templates()
  com = DSpace.fromString('88435/dsp019c67wm88m')

  for col in com.getCollections
    g = col.getSubmitters
    if (g) then
      if false then
        col.removeSubmitters
        col.update
        g.delete
        DSpace.commit
        puts "removed submitters\t#{col.getName}"
      end

    else
      puts "no submitters\t#{col.getName}"
    end
    if (col.getTemplateItem) then
      if (true) then
        col.removeTemplateItem
        col.update
        DSpace.commit
        puts "del template\t#{col.getName}"
      end
    else
      puts "no  template\t#{col.getName}"
    end
  end
end

com = DSpace.fromString('88435/dsp019c67wm88m')

for col in com.getCollections
  steps = []
  for i in [1,2,3] do
    steps <<  col.getWorkflowGroup(i)
  end
  puts [col.getWorkflowGroup(3).getMembers.length, col.getName].join"\t"
end
