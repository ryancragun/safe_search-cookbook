require 'chef/search/query'

# SafeSearch class to implement Chef safe_search extension
class SafeSearch
  class << self
    def search(type, query, args)
      Cache.new.select(to_index(type, query, args))
    end

    def update_cache(type, query, args, response)
      Cache.new.insert(to_index(type, query, args), response)
    end

    def handle_results(current, cached, args)
      ResultHandler.new(current, cached, args).handle
    end

    def parse_args(args = {})
      handler = {}
      handler[:threshold] = args.delete(:threshold) if args.key?(:threshold)
      handler[:merge] = args.delete(:merge) if args.key?(:merge)

      [args, handler]
    end

    def to_index(type, query, args)
      "#{type}-#{query}-#{args}".gsub(/\s+/, '').strip
    end
  end

  # Handle search results
  class ResultHandler
    attr_reader :current, :cached, :threshold, :merge

    def initialize(current, cached, opts = { threshold: 90, merge: false })
      @current = current
      @cached = cached
      # if somebody uses a crazy threshold then default back to 90
      @threshold = (0..100).include?(opts[:threshold]) ? opts[:threshold] : 90
      @merge = opts[:merge]
    end

    def handle
      if merge
        merged = {}
        merged['rows'] = current['rows'].merge(cached['rows'])
        merged['total'] = merged['rows'].length
        merged['start'] = 0
        merged
      elsif current['rows'].length < (cached['rows'].length * (threshold / 100))
        cached
      else
        current
      end
    end
  end

  # SafeSearch Query
  class SafeQuery < Chef::Search::Query
    def initialize(url = nil, *args)
      super(url, *args)
    end

    def search(type, query = '*:*', *args, &block)
      validate_type(type)

      query_args, handler_args = SafeSearch.parse_args(hashify_args(*args))

      rest_response = call_rest_service(type, query: query, **query_args)

      safe_response = SafeSearch.search(type, query, query_args)

      SafeSearch.update_cache(type, query, query_args, rest_response)

      response = SafeSearch.handle_results(rest_response,
                                           safe_response,
                                           handler_args)

      if block
        response['rows'].each { |row| block.call(row) if row }
        unless (response['start'] + response['rows'].length) >= response['total']
          query_args[:start] = response['start'] + (query_args[:rows] || 0)
          search(type, query, query_args, &block)
        end
        true
      else
        [response['rows'], response['start'], response['total']]
      end
    end
  end

  # SafeSearchCache for great good
  class Cache
    attr_accessor :cache_file

    def initialize(cache_file = File.join(Chef::Config[:file_cache_path],
                                          'safe_search_cache.json'))
      @cache_file = cache_file
      init_cache
    end

    def insert(index, data)
      cache = read_cache
      cache[index] = data
      write_cache(cache)
    end

    def select(index)
      read_cache[index]
    rescue
      # There's nothing in the cache so return an empty set
      empty_cache
    end

    private

    def init_cache
      write_cache(empty_cache) unless File.exist?(cache_file)
    end

    def read_cache
      Chef::JSONCompat.parse(IO.read(cache_file))
    end

    def write_cache(new_cache)
      File.open(cache_file, 'w') do |f|
        f.write(Chef::JSONCompat.to_json(new_cache))
      end
    end

    def empty_cache
      {
        'rows' => [],
        'start' => 0,
        'total' => 0
      }
    end
  end
end

# SafeSearchDSL chef DSL extension
module SafeSearchDSL
  def safe_search(*args, &block)
    if block_given? || args.length >= 4
      SafeSearch::SafeQuery.new.search(*args, &block)
    else
      results = []
      SafeSearch::SafeQuery.new.search(*args) do |o|
        results << o
      end
      results
    end
  end

  def search(*args, &block)
    Chef::Log.warn('search is deprecated and unsafe.  Please use safe_search')

    if block_given? || args.length >= 4
      Chef::Search::Query.new.search(*args, &block)
    else
      results = []
      Chef::Search::Query.new.search(*args) do |o|
        results << o
      end
      results
    end
  end
end

# Much of the internal query API was modified between 12.x and 12.1.  Only
# extend support to the DSL if we're running 12.1.x or higher
if Chef::VERSION =~ /^12\.[1-9]+\.\d+/
  Chef::Recipe.send(:include, SafeSearchDSL)
  Chef::Provider.send(:include, SafeSearchDSL)
  Chef::Resource.send(:include, SafeSearchDSL)
  Chef::ResourceDefinition.send(:include, SafeSearchDSL)
end
