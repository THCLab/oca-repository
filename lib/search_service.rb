class SearchService
  attr_reader :es

  def initialize(es)
    @es = es
  end

  def call(hashlink, query)
    results = if hashlink
                search_by_id(hashlink).fetch(:json)
              elsif query
                search_by_query(query).raw_plain['hits']['hits'].map do |r|
                  r.fetch('_id')
                end
              end
  end

  private def search_by_id(hashlink)
    es.index(:odca).type(:schema)
      .get(hashlink)
  end

  private def search_by_query(query)
    es.index(:odca).type(:schema)
      .search(size: 1000, query: {
        match: { json: query }
      })
  end
end
