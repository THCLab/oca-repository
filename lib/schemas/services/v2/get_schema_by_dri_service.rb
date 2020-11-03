# frozen_string_literal: true

module Schemas
  module Services
    module V2
      class GetSchemaByDriService
        attr_reader :es

        def initialize(es)
          @es = es
        end

        def call(dri)
          by_dri(dri, %i[schema_base overlay branch odca])
        end

        private def by_dri(dri, indexes)
          indexes = [indexes] unless indexes.is_a? Array
          query = { bool: { must: [{ match: { DRI: dri } }] } }
          es.msearch([{ index: indexes }, { query: query }])
            .first.results.first
        end
      end
    end
  end
end
