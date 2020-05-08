require 'dspace'

# Module providing procedures for interfacing with the DSpace kernel
module DSpace
  # Class modeling the configuration for the DSpace installation
  class Config

    # Provides the database and ARK server configuration settings to STDOUT
    def print
      puts "DATABASE #{@context.getDBConnection.toString}"
      puts "ark.shoulder  #{DConfig.get('ark.shoulder')}"
    end
  end

  # Retrieves all Items in DSpace which are marked for embargo but for which the embargo has not yet been lifted
  # @return [org.dspace.content.DSpaceObject]
  def self.embargoed()
    items = DSpace.findByMetadataValue('pu.embargo.lift', nil, nil)
  end
end
