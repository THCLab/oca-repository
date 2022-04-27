# frozen_string_literal: true

require 'moneta'

module V01
  module OCA
    module Services
      class GetSchemaBundlesService
        def call(namespace:, sai:)
          oca_storage_path = namespace ? "#{STORAGE_PATH}/namespaces/#{namespace}" : "#{STORAGE_PATH}/oca"
          return [] unless Dir.exists?(oca_storage_path)

          bundles_store = Moneta.new(:DBM, file: "#{oca_storage_path}/db/cb_bundles")
          results = bundles_store[sai]
          bundles_store.close
          results
        end
      end
    end
  end
end
