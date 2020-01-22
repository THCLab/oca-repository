# frozen_string_literal: true

module Schemas
  module Services
    class NewSchemaService
      attr_reader :es

      def initialize(es)
        @es = es
      end

      def call(hashlink:, schema:)
        es.index(:odca).type(:schema)
          .put(hashlink, { json: schema } )
      end
    end
  end
end
