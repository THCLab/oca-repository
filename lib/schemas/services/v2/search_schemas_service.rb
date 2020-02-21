# frozen_string_literal: true

module Schemas
  module Services
    module V2
      class SearchSchemasService
        attr_reader :es

        def initialize(es)
          @es = es
        end

        def call(params)
          results = search(params)

          results.raw_plain['hits']['hits'].map do |r|
            {
              hashlink: r['_id'],
              schema: r['_source']
            }
          end
        rescue
          []
        end

        private def search(params)
          query = if params.empty?
                    { match_all: {} }
                  elsif params['q']
                    { multi_match: { query: params['q'] } }
                  else
                    {
                      bool: {
                        must: params.map do |p|
                          { match: { p[0] => p[1] } }
                        end
                      }
                    }
                  end
          es.index(:_all)
            .search(size: 1000, query: query)
        end
      end
    end
  end
end
