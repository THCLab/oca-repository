# frozen_string_literal: true

module Schemas
  module Repositories
    module V4
      class SchemaReadRepo
        attr_reader :es

        INDEXES = %i[capture_base schema_base overlay branch odca]

        def initialize(es)
          @es = es
        end

        def find_by_sai(sai)
          query = { bool: { must: [{ match: { SAI: sai } }] } }
          record = es.msearch([{ index: INDEXES }, { query: query }])
            .first.results.first

          return record[:_source][:data] unless record[:_index] == 'branch'

          resolve_branch(record)
        end

        def search(namespace:, query:, type:, limit: 1000)
          must = []
          must << { match: { 'namespace' => namespace } } if namespace
          must << { multi_match: { query: query, fields: ['data.*'] } } if query
          must << { match: { 'data.type' => type } } if type

          q = must.empty? ? { match_all: {} } : { bool: { must: must } }

          results = es.index(:_all)
            .search(size: limit, query: q)
            .raw_plain['hits']['hits']

          results = symbolize_keys(results)

          unique_results = results.uniq { |r| r[:_source][:SAI] }
          unique_results.map do |r|
            if r[:_index] == 'branch'
              {
                names: r[:_source][:"name-suggest"].drop(1),
                SAI: r[:_source][:SAI],
                namespace: r[:_source][:namespace],
                schema: resolve_branch(r)
              }
            else
              {
                SAI: r[:_source][:SAI],
                namespace: r[:_source][:namespace],
                schema: r[:_source][:data]
              }
            end
          end
        end

        def search_by_suggestion(suggestion, limit: 10)
          suggest = {
            suggestion: {
              prefix: suggestion,
              completion: {
                field: 'name-suggest'
              }
            }
          }
          results = es.index(:branch)
            .search(size: limit, suggest: suggest)
            .raw_plain['suggest']['suggestion'].first['options']

          results = symbolize_keys(results)

          unique_results = results.uniq { |r| r[:_source][:SAI] }
          unique_results.map do |r|
            {
              matching: r[:text],
              names: r[:_source][:"name-suggest"].drop(1),
              namespace: r[:_source][:namespace],
              SAI: r[:_source][:SAI],
              schema: resolve_branch(r)
            }
          end
        end

        private def resolve_branch(record)
          namespace = record[:_source][:namespace]
          branch = record[:_source][:data]

          capture_base_id = namespace + '/' + branch[:capture_base]
          capture_base = by_id(capture_base_id, :capture_base)[:_source][:data]

          overlay_ids = branch[:overlays].map { |sai| namespace + '/' + sai }
          overlays = by_ids(overlay_ids, :overlay).map { |r| r[:_source][:data] }

          { capture_base: capture_base, overlays: overlays }
        end

        private def by_id(id, index)
          by_ids([id], :capture_base).first
        end

        private def by_ids(ids, indexes)
          indexes = [indexes] unless indexes.is_a? Array
          docs = indexes.map do |index|
            ids.map do |id|
              { _index: index, _id: id }
            end
          end.flatten
          es.mget(docs, exists: nil)
            .select { |r| r[:found] == true }
        end

        private def symbolize_keys(obj)
          return obj.reduce({}) do |memo, (k, v)|
            memo.tap { |m| m[k.to_sym] = symbolize_keys(v) }
          end if obj.is_a? Hash

          return obj.reduce([]) do |memo, v|
            memo << symbolize_keys(v); memo
          end if obj.is_a? Array

          obj
        end
      end
    end
  end
end
