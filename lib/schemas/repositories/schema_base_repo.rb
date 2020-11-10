# frozen_string_literal: true

module Schemas
  module Repositories
    class SchemaBaseRepo
      attr_reader :es, :hashlink_generator

      def initialize(es, hashlink_generator)
        @es = es
        @hashlink_generator = hashlink_generator
      end

      def save(namespace:, schema_base:)
        hashlink = hashlink_generator.call(schema_base)
        record = {
          _id: namespace + '/' + hashlink,
          namespace: namespace,
          DRI: hashlink,
          data: schema_base,
          'name-suggest' => [namespace, schema_base['name']]
        }
        es.index(:schema_base).bulk_index([record])
        record
      end
    end
  end
end
