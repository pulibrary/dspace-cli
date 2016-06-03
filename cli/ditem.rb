class DItem

  def index(force_update)
    java_import org.dspace.discovery.SolrServiceImpl
    idxService = DSpace.getIndexService()
    idxService.indexContent(DSpace.context, @obj, force_update)
  end
end