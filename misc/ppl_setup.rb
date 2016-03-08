#!/usr/bin/env jruby -I lib

require 'dscriptor'
include Dscriptor::Mixins
require 'utils/collection_copy'

Dscriptor.prepare
java_import org.dspace.content.Collection
java_import org.dspace.content.DSpaceObject
java_import org.dspace.handle.HandleManager
java_import org.dspace.eperson.EPerson;
java_import org.dspace.eperson.Group;

Dscriptor.context.setCurrentUser(EPerson.findByNetid(Dscriptor.context, "monikam"))

def eperson_find_or_create_by_netid(dspace_context, hsh)
  netid = hsh[:netid]; 
  return nil unless netid
  p = EPerson.findByNetid(dspace_context, netid)
  if p.nil? then
    p = EPerson.create(dspace_context)
    p.setCanLogIn(true)
    p.setNetid(hsh[:netid])
    p.setFirstName(hsh[:firstname]) if hsh[:firstname]
    p.setLastName(hsh[:lastname]) if hsh[:lastname]
    p.setEmail(hsh[:email]) if hsh[:email];
    puts "Created #{p.toString()}"
    p.update
  else
    puts "Exists #{p.toString()}"
  end
  return p;
end

def group_find_or_create_by_name(dspace_context, group) 
      g = Group.findByName(dspace_context, group);
      if (g.nil?) then 
         g = Group.create(dspace_context);
         g.setName(group)
         g.update();
         puts "Created #{g.toString()}"
      else 
         puts "Exists #{g.toString()}"
      end 
      return g;

end 

def group_search_by_name(dspace_context, partial_name)
      return Group.search(dspace_context, partial_name, 0, 0);
end


def input_forms_xml(comm)
  puts "<!-- #{comm.toString()} #{comm.getName()} -->"
  comm.get_collections.each do |c|
    puts "    <!-- #{c.toString()} #{c.getName()} -->"
    puts "   <name-map collection-handle='#{c.getHandle()}' form-name='researchdata' />"
  end
  comm.getSubcommunities.each do |sc|
    input_forms_xml(sc)
  end
end

def copy_collection(from, under, name, metadata)
  parent_coll = DSpaceObject.fromString(Dscriptor.context, under)
  template_coll = DSpaceObject.fromString(Dscriptor.context, from);

  puts "Name:\n\t#{name}";
  puts "Parent:\n\t#{parent_coll.getName}";
  puts "Template Colection:\n\t#{template_coll.getName}\n\tin #{template_coll.getParentObject().getName}";
  puts "Item Template Metadata:\n";
  metadata.each do |key,val|
    puts "\t#{key}=#{val}"
  end
  options = {
      netid: 'monikam',
      metadata: metadata,
      template_coll: template_coll.getHandle(),
      parent_handle: parent_coll.getHandle(),
      name: name
  };
  copier = DUTILS::Collections::Copy.new(options);
  new_col = copier.doit()
  puts "Created #{new_col.getHandle()}"
  return new_col;
end

def ppl_users
  puts "### ppl users"
  users = [{
               :firstname => 'James B.',
               :lastname => 'Graham',
               :email => 'jgraham@pppl.gov',
               :netid => 'jgraham'
           },
           {
               :firstname => 'George H.',
               :lastname => 'Neilson Jr.',
               :email => 'hneilson@pppl.gov',
               :netid => 'hneilson'
           },
           {
               :firstname => 'Stanley',
               :lastname => 'Kaye',
               :email => 'kaye@pppl.gov',
               :netid => 'skaye'
           }
  ]


  users.each do |hsh|
    eperson_find_or_create_by_netid(  Dscriptor.context, hsh ); 
  end
end

def ppl_groups()
  puts "### ppl groups"
  comms = ["AdvProj", "Eng", "ESH", "IT", "ITER", "ITER", "NSTX", "Plasma", "TAC", "Theory"];
  steps = ['Submitters', 'Reviewers'] 
  comms.each do |comm|
    steps.each do |step|
      group = "PPPL-#{comm}-#{step}";
      group_find_or_create_by_name(Dscriptor.context, group); 
    end
  end
end

def group_add_member(group, p) 
    if p.nil? then 
        $stderr.puts "no such EPerson #{netid}"; 
    else 
       group.addMember(p);
       group.update();
       puts "add #{p.toString} to #{group.toString()} "
    end 
end

def ppl_add_group_members
  #skay to NSRX groups 
  p = eperson_find_or_create_by_netid(  Dscriptor.context, :netid => 'skaye' );
  group_search_by_name(Dscriptor.context, 'PPPL-NSTX').each do   |g|
    group_add_member(g, p); 
  end 

  #monikam, wdressel to all PPPL groups
  mo = eperson_find_or_create_by_netid(  Dscriptor.context, :netid => 'monikam' ); 
  wd = eperson_find_or_create_by_netid(  Dscriptor.context, :netid => 'wdressel' ); 
  group_search_by_name(Dscriptor.context, 'PPPL-').each do   |g|
    group_add_member(g, mo); 
    group_add_member(g, wd); 
  end 
end




#ppl_groups
#ppl_users
#ppl_add_group_members

ppl_comm = '88435/dsp01pz50gz45g';

ntsx_comm = '88435/dsp01j6731612k';
ntsx_coll = '88435/dsp018p58pg29j';
socio_econ_coll = '88435/dsp01sf268746p';
adv_projects = '88435/dsp01k643b3527';


# create collections by hand ???
#Dscriptor.context.commit

metadata = {
    'dc.contributor.other' => 'U. S. Department of Energy contract number DE-AC02-09CH11466',
    'dc.publisher' => 'Princeton Plasma Physics Laboratory, Princeton University',
    'dc.type' => 'Dataset',
    'pu.projectgrantnumber' => '31016 G0001 10003086 101'
}
#copy_collection(ntsx_coll, ntsx_comm, 'NSTX-2', metadata);
#copy_collection(socio_econ_coll, adv_projects, 'Stellarators', metadata);
#copy_collection(socio_econ_coll, adv_projects, 'System Studies', metadata);
#Dscriptor.context.commit


root = '88435/dsp01pz50gz45g'
comm = HandleManager.resolveToObject(Dscriptor.context, root)
input_forms_xml(comm)

#dspace_context.commit
