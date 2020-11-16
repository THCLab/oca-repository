# frozen_string_literal: true

module Schemas
  module Services
    module V1
      class SearchSchemasService
        attr_reader :es

        def initialize(es)
          @es = es
        end

        def call(params)
          begin
            results = if params.empty?
                        search_all
                      else
                        search_by_params(params)
                      end

            results.raw_plain['hits']['hits'].map do |r|
              {
                hashlink: r.fetch('_id'),
                schema: r.fetch('_source')
              }
            end
          rescue
            []
          end
        end

        private def search_all(size: 20)
          es.index(:odca).type(:schema).search(
            size: size,
            query: {
              match_all: {}
            }
          )
        end

        private def search_by_params(params)
          query = if params['q']
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
          es.index(:odca).type(:schema)
            .search(size: 1000, query: query)
        end
      end
    end
  end
end
