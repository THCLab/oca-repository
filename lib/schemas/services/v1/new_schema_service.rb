# frozen_string_literal: true

module Schemas
  module Services
    module V1
      class NewSchemaService
        attr_reader :es

        def initialize(es)
          @es = es
        end

        def call(hashlink:, schema:)
          es.index(:odca).type(:schema)
            .put(hashlink, schema)
        end
      end
    end
  end
end
