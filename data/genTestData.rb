#!/usr/bin/env jruby 
require 'yaml';
require 'faker';
require 'dspace'

test_data_file = "data/genTestData.yml";

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
          puts "created in #{parent.getName},#{col["name"]}\t#{coll.getHandle}\t#{coll.getName}\t"
          n = col["nitems"] || 0
          n.times do
            md = fake_metadata
            item = DItem.install(coll, md)
            DSpace.create(item).index(true)
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
  puts "created #{new_col.getHandle} #{new_col.getName}"
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
  metadata['dc.date.issued'] = Faker::Date.between("6/1/2010", DateTime.now).to_s
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
  DSpace.login(ENV['USER'])
end

def doit(test_data_file)
init_dspace
generate(test_data_file)
DSpace.commit
end






