# frozen_string_literal: true

module Schemas
  module Services
    class GetSchemaService
      attr_reader :es

      def initialize(es)
        @es = es
      end

      def call(id)
        by_id(id).fetch('json')
      end

      private def by_id(id)
        es.index(:odca).type(:schema).get(id)
      end
    end
  end
end
