class DMetadataField

  # Generate a Hash from an Array of field values keyed by the full name of the metdata field
  # @param fieldValueArray [Array<DMetadataField>]
  # @return [Hash]
  def self.arrayToHash(fieldValueArray)
    mdHsh = {}
    fieldValueArray.each do |k, v|
      mdHsh[k.fullName] ||= []
      mdHsh[k.fullName] << v
    end
    return mdHsh
  end
end
