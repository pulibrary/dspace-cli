require 'dspace'

module DSpace
  class Config
    def print
      puts "DATABASE #{@context.getDBConnection.toString}"
      puts "ark.shoulder  #{DConfig.get('ark.shoulder')}"
    end
  end
end