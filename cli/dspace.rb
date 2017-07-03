require 'dspace'

module DSpace
  class Config
    def print
      puts "DATABASE #{@context.getDBConnection.toString}"
      puts "ark.shoulder  #{DConfig.get('ark.shoulder')}"
    end
  end

  def self.embargoed()
    items = DSpace.findByMetadataValue('pu.embargo.lift', nil, nil)
  end
end