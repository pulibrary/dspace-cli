require 'dspace'
##
# This class extends the DSpace module Config from the dspace jruby gem for 
# Princeton-specific functionality.
# @see https://github.com/pulibrary/dspace-jruby
module DSpace
  class Config
    def print
      puts "DATABASE #{@context.getDBConnection.toString}"
      puts "ark.shoulder  #{DConfig.get('ark.shoulder')}"
    end
  end

  # Return list of DSOs of embargoed data in DSpace, unrestricted by value or type
  # TODO: delete "items = " for clarity
  def self.embargoed()
    items = DSpace.findByMetadataValue('pu.embargo.lift', nil, nil)
  end
end