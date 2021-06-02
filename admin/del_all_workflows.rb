#!/usr/bin/env jruby -I ../dspace-jruby/lib

# filename is self explanatory

# "findAll nil" defaults to DSpace.context
# TODO: Make nil default in dpsace-jruby/dwork.rb so argument not necessary
wfs = DWorkflowItem.findAll nil
wfs.each do |w|
  w.deleteWrapper
  w.getItem.delete
  DSpace.commit
end
