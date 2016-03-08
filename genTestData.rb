#!/usr/bin/env jruby  -I lib -I utils
require 'yaml';
require 'faker';
require 'dspace'

test_data_file = "testdata.yml";

def generate(file)
  test_data = YAML.load_file(file)
  test_data["communities"].each do |comm|
    parent_name = comm["name"];
    if parent_name then
      puts "zap_community #{parent_name}"
      zap_community(parent_name)
      parent = create_community(parent_name)
      puts "created #{parent.getHandle}\t#{parent.getName}"
      collections = comm["collections"];
      if (collections) then
        collections.each do |col|
          coll = create_collections(parent, col["name"])
          puts "created in #{parent.getName}\t#{coll.getHandle}\t#{coll.getName}\t"
          n = col["nitems"] || 0
          n.times do
            md = fake_metadata
            item = DItem.install(coll, md)
            puts "created in #{parent.getName}\t#{coll.getHandle}\t#{coll.getName}\th=#{item.getHandle()} #{item.getName}"
          end
        end
      end
    end
  end
end

def zap_community(comm_name)
  DCommunity.findAll(comm_name).each do |c|
    c.delete();
  end
end

def create_community(comm_name)
  parent = Community.create(nil, DSpace.context)
  parent.setMetadata("name", comm_name)
  parent.update
  DSpace.commit
  return parent
end

def create_collections(parent, name)
  new_col = Collection.create(DSpace.context)
  new_col.setMetadata("name", name)
  new_col.update
  parent.addCollection(new_col)
  return new_col;
end

def fake_metadata
  metadata = {};

  authors = [];
  (1+rand(3)).times do
    authors << "#{Faker::Name.last_name}, #{Faker::Name.first_name}"
  end
  metadata['dc.contributor.author'] = authors;

  metadata['dc.type'] = 'Article';

  metadata['dc.title'] = Faker::Book.title
  metadata['dc.publisher'] =  Faker::Book.publisher
  metadata['dc.date.issued'] = Faker::Date.between("1/1/2000", DateTime.now).to_s
  #journal =  Faker::Commerce.department;
  journal = metadata['dc.title'].split[0]
  if ( 0 == rand(1)) then
    journal = "Journal of " + journal
  else
    journal = journal + " Journal";
  end
  metadata['dc.relation.ispartofseries'] = journal

  # abstract with up to three paragraphs containing up to 10 sentences - where sentences have up to 12 words.
  abstract = "";
  npar = 1 + rand(3)
  nsent = 3 + rand(10)
  nwords = 6 + rand(12)
  npar.times do
    nsent.times do
      abstract = abstract + " " + Faker::Lorem.sentence(nwords)
    end
    abstract = "#{abstract}\n";
  end
  metadata['dc.description.abstract'] = abstract

  return metadata
end

def init_dspace
  DSpace.load()
  java_import org.dspace.content.Collection
  java_import org.dspace.content.Community
  java_import org.dspace.content.Item

  admin_user = DGroup.find(DGroup::ADMIN_ID).getMembers()[0]
  puts "Using user account: #{admin_user.getEmail()}"
  DSpace.context.setCurrentUser(admin_user)
end


def export(file)
  test_data = YAML.load_file(file)
  test_data["communities"].each do |comm|
    parent_name = comm["name"];
    if parent_name then
      dir = parent_name.gsub(/ /, "_")
      puts "---"
      puts "echo 'exporting #{parent_name}'"
      puts "mkdir -p #{dir}"
      puts "cd #{dir}"
      i = 0;
      DCommunity.findAll(parent_name).each do |com|
        com.getCollections.each do |col|
         dir = col.getName.gsub(/ /, '_')
         puts "mkdir -p #{dir}"
         puts "$DSPACE_HOME/bin/dspace export -t COLLECTION -i #{col.getHandle} -d #{dir} -n 1 -m"
         i = i + 1000;
        end
      end
      puts "cd .."
    end
  end
end

def import(file)
  test_data = YAML.load_file(file)
  test_data["communities"].each do |comm|
    parent_name = comm["name"];
    if parent_name then
      dir = parent_name.gsub(/ /, "_")
      puts "---"
      puts "echo 'importing #{parent_name}' from #{dir}"
      puts "cd #{dir}"
      i = 0;
      DCommunity.findAll(parent_name).each do |com|
        com.getCollections.each do |col|
          dir = col.getName.gsub(/ /, '_')
          puts "echo 'importing #{col.getName}' from #{dir}"
          puts "$DSPACE_HOME/bin/dspace import -c #{col.getHandle} -s #{dir} -e $EPERSON  -a -m #{dir}/mapfile "
        end
      end
      puts "cd .."
    end
  end
end
if (false) then
  init_dspace
  generate(test_data_file)
  DSpace.commit
else
  init_dspace
  export(test_data_file)

  import(test_data_file)
end

#md =  fake_metadata







