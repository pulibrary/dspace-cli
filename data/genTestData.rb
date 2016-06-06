#!/usr/bin/env jruby 
require 'yaml';
require 'faker';
require 'dspace'
require 'cli/ditem'

test_data_file = "data/genTestData.yml";

def recreate_community(comm_name)
  DCommunity.all.each do |c|
    if c.getName == comm_name then
      puts "delete community #{comm_name}"
      c.delete()
    end
  end
  return DCommunity.create(comm_name)
end

def generate(file)
  test_data = load_file(file)
  puts test_data
  test_data["communities"].each do |comm|
    parent_name = comm["name"];
    parent = recreate_community(parent_name)
    puts "created #{parent.getHandle}\t#{parent.getName}"
    comm["collections"].each do |col|
      coll = DCollection.create(col["name"], parent)
      puts "created in #{parent.getName} #{coll.getHandle} #{coll.getName}"
      col["nitems"].times do
        md = fake_metadata
        item = DItem.install(coll, md)
        DSpace.create(item).index(true)
        puts "created in #{parent.getName}\t#{coll.getHandle}\t#{coll.getName}\th=#{item.getHandle()} #{item.getName}"
      end
    end
  end
end

def load_file(file)
  test_data = YAML.load_file(file)
  error, comi = [0, 0]
  test_data["communities"].each do |comm|
    if (comm["name"] || "").empty? then
      $stderr.puts "Community #{comi} has no name"
      error += 1
    else
      comm["collections"] ||= []
      colli = 0;
      comm['collections'].each do |col|
        if (col["name"] || "").empty? then
          $stderr.puts "Collection #{colli} in Community #{comi} has no name"
          error += 1
        else
          col["nitems"] ||= 0
        end
      end
      comi += 1
    end
  end
  return (error == 0) ? test_data : {"communities" => []}
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
  metadata['dc.publisher'] = Faker::Book.publisher
  metadata['dc.date.issued'] = Faker::Date.between("6/1/2010", DateTime.now).to_s
  #journal =  Faker::Commerce.department;
  journal = metadata['dc.title'].split[0]
  if (0 == rand(1)) then
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

def doit(test_data_file)
  DSpace.load()
  java_import org.dspace.content.Collection
  java_import org.dspace.content.Community
  java_import org.dspace.content.Item
  DSpace.login(ENV['USER'])

  generate(test_data_file)
  #DSpace.commit
end


doit(test_data_file)





