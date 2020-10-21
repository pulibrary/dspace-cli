# frozen_string_literal: true

module DSpace
  module CLI
    class BrowseIndex
      java_import(org.dspace.core.ConfigurationManager)
      java_import(org.dspace.browse.BrowseIndex)
      java_import(org.dspace.browse.BrowseEngine)
      java_import(org.dspace.browse.BrowserScope)
      java_import(org.dspace.sort.SortOption)
      java_import(org.dspace.discovery.DiscoverQuery)
      java_import(org.dspace.discovery.SearchService)
      java_import(org.dspace.core.Constants)
      java_import(org.apache.solr.client.solrj.impl.HttpSolrServer)
      java_import(org.dspace.utils.DSpace)

      def self.kernel
        ::DSpace
      end

      def self.default_browse_index_name
        'title'
      end

      def self.browse_index_name
        Java::OrgDspaceCore::ConfigurationManager.getProperty('webui.collectionhome.browse-name') || default_browse_index_name
      end

      def self.browse_index
        Java::OrgDspaceBrowse::BrowseIndex.getBrowseIndex(browse_index_name)
      end

      def self.browse_engine
        Java::OrgDspaceBrowse::BrowseEngine.new(kernel.context)
      end

      attr_reader :number, :offset, :per_page, :et_al, :items_withdrawn, :items_discoverable

      def initialize(container:, number: -1, offset: 0, per_page: nil, et_al: nil, items_withdrawn: false, items_discoverable: true)
        @container = container
        @number = number
        @offset = offset
        @per_page = per_page || self.class.per_page
        @et_al = et_al || self.class.et_al
        @items_withdrawn = items_withdrawn
        @items_discoverable = items_discoverable
      end

      def self.et_al
        Java::OrgDspaceCore::ConfigurationManager.getIntProperty('webui.browse.author-limit', -1)
      end

      def self.per_page
        Java::OrgDspaceCore::ConfigurationManager.getIntProperty('webui.collectionhome.perpage', 20)
      end

      def build_browser_scope
        scope = Java::OrgDspaceBrowse::BrowserScope.new(self.class.kernel.context)
        scope.setBrowseContainer(@container)
        scope.setBrowseIndex(self.class.browse_index)
        scope.setEtAl(self.class.et_al)
        scope.setOffset(offset)
        scope.setResultsPerPage(per_page)

        # This is only applied if there is sorting
        if number != -1
          scope.setSortBy(number)
          scope.setOrder(Java::OrgDspaceSort::SortOption::DESCENDING)
        end

        scope
      end

      def browser_scope
        @browser_scope ||= build_browser_scope
      end

      def browse_info
        self.class.browse_engine.browse(browser_scope)
      end

      def browse_item_results
        @browse_item_results ||= begin
          values = browse_info.getResults
          values.to_a
        end
      end

      def results
        browse_item_results.map do |browse_item|
          item_id = browse_item.getID
          Item.find(item_id)
        end
      end

      def build_query
        query = Java::OrgDspaceDiscovery::DiscoverQuery.new

        if @container.is_a?(Java::OrgDspaceContent::Community)
          query.addFilterQueries("location.comm: #{@container.getID}")
        else
          query.addFilterQueries("location.coll: #{@container.getID}")
        end

        if items_withdrawn
          query.addFilterQueries('withdrawn:true')
        elsif !items_discoverable
          query.addFilterQueries('discoverable:false')
        end

        query.addFilterQueries("search.resourcetype: #{Java::OrgDspaceCore::Constants::ITEM}")

        query
      end

      def query
        @query ||= build_query
      end

      def self.service_manager
        kernel.getServiceManager
      end

      def self.get_service_by_name(class_name, service_class)
        service_manager.getServiceByName(class_name, service_class)
      end

      def self.search_service
        get_service_by_name('org.dspace.discovery.SearchService', Java::OrgDspaceDiscovery::SearchService)
      end

      def searcher
        self.class.search_service
      end

      def search
        searcher.search(self.class.kernel.context, query, items_withdrawn || !items_discoverable)
      end

      def self.configuration_service
        dspace = Java::OrgDspaceUtils::DSpace.new
        dspace.getConfigurationService
      end

      def self.solr_service
        configuration_service.getProperty('discovery.search.server')
      end

      def build_solr
        client = Java::OrgApacheSolrClientSolrjImpl::HttpSolrServer.new(self.class.solr_service)
        client.setBaseURL(self.class.solr_service)
        client.setUseMultiPartPost(true)
        client
      end

      def solr
        @solr ||= build_solr
      end

      def delete_query
        output = []

        output << if @container.is_a?(Java::OrgDspaceContent::Community)
                    "location.comm: #{@container.getID}"
                  else
                    "location.coll: #{@container.getID}"
                  end

        output << "search.resourcetype: #{Java::OrgDspaceCore::Constants::ITEM}"
        output.join(' AND ')
      end

      def delete_all_documents
        solr.deleteByQuery(delete_query)
        solr.commit
      end
    end
  end
end
