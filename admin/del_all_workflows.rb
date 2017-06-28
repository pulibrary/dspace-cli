#!/usr/bin/env jruby -I ../dspace-jruby/lib 

wfs = DWorkflowItem.findAll nil
wfs.each do |w|
  w.deleteWrapper
  w.getItem.delete
  DSpace.commit
end
