class DItem

  def getBitstreams(bundleName = "ORIGINAL")
    bundles = bundleName.nil? ? @obj.getBundles : @obj.getBundles(bundleName)
    bits = []
    bundles.each do |b|
       bits += b.getBitstreams
    end
    bits
  end

end