#!/usr/bin/env jruby
require 'http'
require 'json'
require 'yaml'
require 'rack'
require 'optparse'

require File.join(File.dirname(__FILE__), '..', 'dspace')

# Given handles for communities on the command line, develop basic reports

module Statistics
  class Community
    DSpaceObjectTypes = { 'bitstream' => { 'type' => 0, 'bundleName' => 'ORIGINAL' },
                          'item' => { 'type' => 2 },
                          'collection' => { 'type' => 3 },
                          'community' => { 'type' => 4 } }.freeze

    # Given options from the command line, narrow the kind of stats to be calculated
    def initialize(options)
      communities = options['communities']
      raise 'mising communities ' unless communities && !communities.empty?

      @community_query = []
      error = false
      communities.each do |hsh|
        id = hsh['id'].to_i
        if id < 0
          error = true
          puts 'all community id must be >= 0'
        end
        community_name = hsh['name']
        if community_name.empty?
          $stderr.print "ERROR: invalid community #{hsh}"
          error = true
        end
        @community_query << { 'name' => community_name,
                              'query' => { 'owningComm' => id } }
      end
      raise 'invalid communities list' if error

      exclude_ips = options['exclude_ips']
      raise 'exclude_ips must be an array' unless exclude_ips.class == Array

      @exclude_ips = if exclude_ips.empty?
                       {}
                     else
                       { '-ip' => "(#{exclude_ips.join(' OR ')})" }
                     end

      @solrCoreBase = options['solrStatisticsServer'] || ConfigurationManager.getProperty('solr-statistics', 'server')
      @time_slots = options['time_slots'] || ['']
      raise 'must have at least one time_slot definition' if @time_slots.empty?

      @time_ranges = @time_slots.collect { |s| s['slot'] }
      @time_range_names = @time_slots.collect { |s| s['name'] }

      @top_bitstreams = options['top_bitstreams'] || { 'number' => 10, 'time_slot' => @time_slots[0] }

      @verbose = options['verbose']

      $stdout.puts to_yaml if @verbose

      DSpace.load(dspace_root_path: options['dspaceHome'])
      @context = DSpace.context

      java_import org.dspace.content.Community
      java_import org.dspace.content.Collection
      java_import org.dspace.content.Bitstream
    end

    def verbose?
      @verbose
    end

    # For Community, get counts for each collection, repeat for all Communities
    def collection_counts(outfile)
      print_basic_report_info(outfile)
      if @verbose
        outfile.puts '# @time_slots:'
        @time_slots.each do |ts|
          outfile.puts "# \t#{ts['name']}\t#{ts['slot']}"
        end
      end
      outfile.puts '# '
      {
        'bitstream' => 'bitstream access count',
        'item' => 'item page access count',
        'collection' => 'collection page access count'
      }.each do |key, desc|
        outfile.puts "# type=#{key}:\t #{desc}  in COMMUNITY.NAME"
      end
      outfile.puts '# '

      @community_query.each do |hsh|
        community_query = hsh['query']
        community_name = hsh['name']

        $stdout.puts community_name.to_s if @verbose

        headers = ['COMMUNITY.NAME', 'COLLECTION.ID', 'COLLECTION.HANDLE', 'type'] << @time_range_names
        headers.push('COLLECTION.NAME')
        outfile.puts headers.join("\t")
        {
          'bitstream' => 'bitstream access count',
          'item' => 'item page access count',
          'collection' => 'collection page access count'
        }.each do |key, _desc|
          slot_stats = {}

          @time_ranges.each do |range|
            slot_stats[range] = getStatsFor(community_query, DSpaceObjectTypes[key], range, 'owningColl')
          end

          # total counts first
          naccess = @time_ranges.collect { |range| slot_stats[range]['response']['numFound'] }
          col = 'ALL'
          collection_name = 'ALL-COLLECTIONS'
          collection_handle = ''
          outfile.puts "#{community_name}\tCOLLECTION.#{col}\t#{collection_handle}\t#{key}\t#{naccess.join("\t")}\t#{collection_name}"
          # collection facet counts
          colstats = {}
          colnames = []
          @time_ranges.each do |range|
            colstats[range] = {}
            colnums = slot_stats[range]['facet_counts']['facet_fields']['owningColl']
            (0..colnums.length / 2 - 1).each do |i|
              c = colnums[2 * i]
              n = colnums[2 * i + 1]
              colstats[range][c] = n if n > 0
              colnames << c unless colnames.include?(c)
            end
          end
          colnames.each do |col|
            collection = Collection.find(@context, col.to_i)
            if collection.nil?
              collection_name = "COLLECTION.#{col}"
              collection_handle = 'NULL'
            else
              collection_name = collection.getName.gsub(/\s+/, ' ')
              collection_handle = collection.getHandle
            end
            naccess = @time_ranges.collect { |range| colstats[range][col] }
            outfile.puts "#{community_name}\t#{collection}\t#{collection_handle}\t#{key}\t#{naccess.join("\t")}\t#{collection_name}"
          end
          outfile.print "\n"
          $stdout.print "\n"
        end
      end
    end

    def top_bitstreams(outfile)
      print_basic_report_info(outfile)
      max = @top_bitstreams['number']
      time_range = @top_bitstreams['time_slot']['slot']
      slot_name = @top_bitstreams['time_slot']['name']
      outfile.puts "# Top Bitstreams downloads for #{slot_name}"
      outfile.puts '#'
      outfile.puts ['TOP', 'COMMUNITY', 'N-DOWNLOADS', 'BITSTREAM', 'ITEM-id', 'ITEM-handle', 'ITEM-name',
                    'COLLECTION-id', 'COLLECTION-handle', 'COLLECTION-name', '...'].join("\t")
      @community_query.each do |hsh|
        community_query = hsh['query']
        community_name = hsh['name']

        stats = getStatsFor(community_query, DSpaceObjectTypes['bitstream'], time_range, 'id')
        colnums = stats['facet_counts']['facet_fields']['id']
        nline = 0
        (0..colnums.length / 2 - 1).each do |i|
          c = colnums[2 * i]
          n = colnums[2 * i + 1]

          bitstream = Bitstream.find(@context, c.to_i)
          if bitstream.nil?
            warn "Can't find BITSTREAM.#{c_to_i}"
            break
          end
          line = [i, community_name, n, bitstream.getName]
          item = bitstream.getParentObject
          if item.nil?
            warn "Bitstream #{bitstream} has no parent"
          else
            line << item << item.getHandle << item.getName.gsub(/\s+/, ' ')
            prtcolname = true
            cli_item = DSpace::CLI::Item.new(item)
            cli_item.collections.each do |p|
              line << p.id << p.model.getHandle
              next unless prtcolname

              puts "NAME #{p.model.getName}"
              line << p.model.getName
              prtcolname = false
            end
            outfile.puts line.join("\t")
            nline += 1
          end
          break if nline == max
        end
      end
    end

    private

    # Request data from Solr
    def getStatsFor(community, type, timeRange, facet_field)
      query = @solrCoreBase +
              '/select?' +
              solrParams('facet' => 'true',
                         'facet.mincount' => 1,
                         'facet.limit' => -1,
                         'facet.sort' => 'count',
                         'facet.field' => facet_field)
      escaped_time_range = Rack::Utils.escape("[#{timeRange}]")
      query += "&fq=time:#{escaped_time_range}" unless timeRange.empty?
      query = query + '&q=' + Rack::Utils.escape('NOT epersonid:["" TO *]')

      props = { '-isBot' => 'true' }.merge(community).merge(type).merge(@exclude_ips)
      props.each do |k, v|
        query = "#{query}+#{k}:#{Rack::Utils.escape(v)}"
      end
      if @verbose
        $stdout.puts "#DEBUG #{query}"
      else
        print '.'
        $stdout.flush
      end
      uri = URI(query)
      getJsonStats(uri)
    end

    # Prepare query for solr
    def solrParams(props = {})
      params = 'wt=json'
      props = { 'indent' => 'true', 'rows' => '0' }.merge(props)
      props.each do |k, v|
        params = "#{params}&#{k}=#{Rack::Utils.escape(v)}"
      end
      params
    end

    # Make request and parse JSON
    def getJsonStats(uri)
      res = HTTP.get(uri)
      stats = JSON.parse(res)
      stats
    rescue Exception => e
      puts "data error #{uri}:  #{e.message}"
      {}
    end

    # NOTE: Doesn't seem to be used
    def self.printArrOfHash(outfile, pre, arr)
      first = true
      arr.each do |hsh|
        if first
          outfile.puts "#{pre}\t" + hsh.keys.join("\t")
          first = false
        end
        outfile.print "#{pre}\t"
        hsh.keys.each do |k|
          v = hsh[k]
          outfile.print "#{v}\t"
        end
        outfile.print "\n"
      end
    end

    # Print config info, usually used at the top of a file / std out
    def print_basic_report_info(outfile)
      outfile.puts "# report-date: #{Time.now}"
      outfile.puts "# solr-core: #{@solrCoreBase}"
      outfile.puts "# hostname: #{Socket.gethostname}"
      outfile.puts '#'
    end

    def self.run
      options = {}
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: #{__FILE__} [options]"

        opts.on('-c', '--collection_counts file', 'cumulative counts for collections') do |v|
          options[:counts] = v
        end

        opts.on('-b', '--bitstreams file', 'most downloaded bitstreams') do |v|
          options[:top_bitstreams] = v
        end

        opts.on('-y', '--yml options', 'yml options file') do |v|
          options[:yml_options] = v
        end

        opts.on('-v', '--[no-]verbose', 'Run verbosely') do |v|
          options[:verbose] = v
        end

        opts.on('-h', '--help', 'Prints this help') do
          puts opts
          exit
        end
      end

      begin
        parser.parse!
        init_file = options[:yml_options] || 'statistics/community.yml'
        puts "using #{init_file}"
        yaml_options = YAML.load_file(init_file)

        collection_counts_file = options.delete :counts
        top_bitstreams_file = options.delete :top_bitstreams

        raise 'must give collection_counts and/or bitstreams file' if collection_counts_file.nil? && top_bitstreams_file.nil?

        options.each do |k, v|
          yaml_options[k.to_s] = v
        end
        stats_maker = new(yaml_options)
      rescue Exception => e
        puts e.message
        puts parser.help
      end

      if collection_counts_file
        collection_counts_out = File.open(collection_counts_file, 'w')
        stats_maker.collection_counts(collection_counts_out)
        collection_counts_out.close
      end

      if top_bitstreams_file
        top_bitstreams_out = File.open(top_bitstreams_file, 'w')
        stats_maker.top_bitstreams(top_bitstreams_out)
        top_bitstreams_out.close
      end
    end
  end
end

Statistics::Community.run
