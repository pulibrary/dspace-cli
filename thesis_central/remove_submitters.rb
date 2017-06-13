require 'cli/dspace.rb'
DSpace.load

com = DSpace.fromString('88435/dsp019c67wm88m')
DSpace.login 'monikam'

for col in com.getCollections
  g = col.getSubmitters
  if (g) then
    col.removeSubmitters
    col.update
    g.delete
    DSpace.commit
    puts "#{col.getName}  removed submitters"
  else
    puts "#{col.getName}  no submitters"
  end
end

