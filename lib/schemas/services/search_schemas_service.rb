# frozen_string_literal: true

module Schemas
  module Services
    class SearchSchemasService
      attr_reader :es

      def initialize(es)
        @es = es
      end

      def call(query)
        results = if query
                    search_by_query(query)
                  else
                    search_all
                  end

        results.raw_plain['hits']['hits'].map do |r|
          {
            hashlink: r.fetch('_id'),
            schema: r.fetch('_source').fetch('json')
          }
        end
      end

      private def search_all(size: 20)
        es.index(:odca).type(:schema)
          .search(size: size, query: {
            match_all: { }
          })
      end

      private def search_by_query(query)
        es.index(:odca).type(:schema)
          .search(size: 1000, query: {
            match: { json: query }
          })
      end
    end
  end
end
