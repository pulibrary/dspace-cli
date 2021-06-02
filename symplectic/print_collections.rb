#!/usr/bin/env jruby

# Create YAML of hash of all Collections / workflow groups into standard out.

require 'highline/import'
require 'dspace'
require 'yaml'

DSpace.load
puts "\n"

hsh = {}
DCollection.all.collect { |c| c.getName}.sort.each do |name|
  col = DSpace.findByMetadataValue('dc.title', name, DConstants::COLLECTION)[0]
  hsh[col.getID] = { 'name' => col.getName, 'handle' => col.getHandle, 'parent' => col.getParentObject.getName, 'workflow' => {} }
  colhsh = hsh[col.getID]
  g = col.getSubmitters
  colhsh['workflow']['submit'] = g.getName if g
  [1, 2, 3].each do |i|
    g = col.getWorkflowGroup(i)
    colhsh['workflow']["step_#{i}"] = g.getName if g
  end
end
puts YAML.dump(hsh)
