require 'optparse'

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} handle.."
end


require 'dspace'
DSpace.load

com = DSpace.fromString('88435/dsp01td96k251d')

def doit(com)
  dcom = DSpace.fromString(com)
  colls = DSpace.create(dcom).getCollections()
  for c in colls do
    puts [c.getHandle, c.getParentObject.getHandle, c.getName].join("\t")
  end
end


begin
  parser.parse!
  raise "must give at least one community" if ARGV.empty?

  DSpace.load

  ARGV.each do |str|
    doit(str)
  end
rescue Exception => e
  puts e.message;
  puts parser.help();
end

