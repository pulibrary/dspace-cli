# UNFINISHED
# 
# If worthwhile, develop appropriate CLI to handle these requests, or at least
# call the function at the end of the script.

ids = %w(abaruzzi agerwel agothman akatesnel anikolop co3 colleenk dreay dsantam hbennett jb32 jgli kappleby lball lgilbert mcreid mgu mwgeorge phebed spiotrow strudler)

require 'dspace'
DSpace.load

def doit(ids)
  ids.each do |id|
    puts id
    p = DEPerson.find(id)
    p.setCanLogIn false
    p.update
    puts p
  end
end
