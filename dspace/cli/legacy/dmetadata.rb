# frozen_string_literal: true

##
# This class extends DMetadata from the dspace jruby gem for Princeton-specific
# functionality.
# @see https://github.com/pulibrary/dspace-jruby
class DMetadataField
  def self.array_to_hash(fieldValueArray)
    mdHsh = {}
    fieldValueArray.each do |k, v|
      mdHsh[k.fullName] ||= []
      mdHsh[k.fullName] << v
    end
    mdHsh
  end
end
