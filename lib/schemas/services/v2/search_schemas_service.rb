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
              namespace: r['_source']['namespace'],
              DRI: r['_source']['DRI'] || r['_id'],
              schema: r['_source']['data'] || r['_source']
            }
          end
        rescue
          []
        end

        private def search(params)
          size = params.delete('limit')
          query = params.each_with_object({}) do |(key, value), memo|
            memo[:bool] = { must: [] } unless memo[:bool]
            case key
            when 'q'
              memo[:bool][:must] << {
                multi_match: { query: value, fields: ['data.*'] }
              }
            when :namespace
              memo[:bool][:must] << { match: { 'namespace' => value } }
            else
              memo[:bool][:must] << {
                match: {
                  (key[0] == '_' ? key : 'data.' + key) => value
                }
              }
            end
          end
          query = { match_all: {} } if query.empty?

          es.index(:_all)
            .search(size: size || 1000, query: query)
        end
      end
    end
  end
end
