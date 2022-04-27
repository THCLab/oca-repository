# frozen_string_literal: true

require 'moneta'

module V01
  module OCA
    module Repositories
      class SchemaReadRepo
        attr_reader :es

        def initialize(es)
          @es = es
        end

        def find_by_namespace_sai(namespace:, sai:)
          oca_storage_path = namespace ? "#{STORAGE_PATH}/namespaces/#{namespace}" : "#{STORAGE_PATH}/oca"
          return {} unless Dir.exists?(oca_storage_path)
          store = Moneta.new(:DBM, file: "#{oca_storage_path}/db/oca")
          record = store.key?(sai) ? JSON.parse(store[sai]) : nil
          store.close

          return {} unless record
          return resolve_bundle(namespace: namespace, record: record) if record['type'] == 'bundle'

          JSON.parse(File.read("#{oca_storage_path}/#{sai}.json"))
        end

        def find_by_namespace(namespace)
          oca_storage_path = namespace ? "#{STORAGE_PATH}/namespaces/#{namespace}" : "#{STORAGE_PATH}/oca"
          return [] unless Dir.exists?(oca_storage_path)
          store = Moneta.new(:DBM, file: "#{oca_storage_path}/db/oca")
          records = []
          store.each_key do |key|
            record = JSON.parse(store[key])
            if record['type'] == 'bundle'
              records << resolve_bundle(namespace: namespace, record: record)
            else
              records << JSON.parse(File.read("#{oca_storage_path}/#{key}.json"))
            end
          end
          store.close

          records
        end

        def search(namespace:, query:, limit: 1000)
          response = es.search(index: ['capture_base', 'meta'], size: limit, q: query)
          results = response.body['hits']['hits']

          unique_results = results.uniq { |r| r['_source']['capture_base_sai'] }
          unique_results.map do |r|
            {
              namespace: r['_source']['namespace'],
              capture_base_sai: r['_source']['capture_base_sai']
            }
          end
        end

        def search_by_suggestion(suggestion)
          suggest = {
            suggest: {
              prefix: suggestion,
              completion: {
                field: 'suggest'
              }
            }
          }
          response = es.search(index: 'meta', body: { suggest: suggest })
          results = response.body['suggest']['suggest'].first['options']

          unique_results = results.uniq { |r| r['_source']['capture_base_sai'] }
          unique_results.map do |r|
            {
              matching: r['text'],
              name: r['_source']['name'],
              namespace: r['_source']['namespace'],
              capture_base_sai: r['_source']['capture_base_sai']
            }
          end
        end

        private def resolve_bundle(namespace:, record:)
          oca_storage_path = namespace ? "#{STORAGE_PATH}/namespaces/#{namespace}" : "#{STORAGE_PATH}/oca"
          capture_base = JSON.parse(File.read("#{oca_storage_path}/#{record['capture_base']}.json"))

          overlays = []
          record['overlays'].each do |ov_sai|
            overlays << JSON.parse(File.read("#{oca_storage_path}/#{ov_sai}.json"))
          end

          { capture_base: capture_base, overlays: overlays }
        end
      end
    end
  end
end
