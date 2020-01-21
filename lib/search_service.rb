class SearchService
  attr_reader :es

  def initialize(es)
    @es = es
  end

  def call(query)
    results = search(query).raw_plain['hits']['hits']
    p results
  end

  private def search(query)
    es.index(:odca).type(:schema)
      .search(size: 1000, query: {
        match: { json: query }
      })
  end
end
