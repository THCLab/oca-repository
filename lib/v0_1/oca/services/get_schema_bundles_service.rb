# frozen_string_literal: true

require 'moneta'

module V01
  module OCA
    module Services
      class GetSchemaBundlesService
        def call(namespace:, sai:)
          return [] unless Dir.exists?("#{STORAGE_PATH}/namespaces/#{namespace}")

          bundles_store = Moneta.new(:DBM, file: "#{STORAGE_PATH}/namespaces/#{namespace}/db/cb_bundles")
          results = bundles_store[sai]
          bundles_store.close
          results
        end
      end
    end
  end
end
