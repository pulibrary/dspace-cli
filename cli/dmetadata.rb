class DMetadataField
  def self.arrayToHash(fieldValueArray)
    mdHsh = {}
    fieldValueArray.each do |k, v|
      mdHsh[k.fullName] ||= []
      mdHsh[k.fullName] << v
    end
    return mdHsh
  end
end