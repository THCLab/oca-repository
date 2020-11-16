# frozen_string_literal: true

module Schemas
  module Repositories
    class SchemaWriteRepo
      attr_reader :es, :hashlink_generator

      def initialize(es, hashlink_generator)
        @es = es
        @hashlink_generator = hashlink_generator
      end

      def save(namespace:, schema:)
        schema_base_record = save_schema_base(
          namespace: namespace, schema_base: schema.fetch(:schema_base)
        )
        return schema_base_record unless schema[:overlays]

        overlay_records = []
        schema.fetch(:overlays).each do |overlay|
          overlay_records << save_overlay(
            namespace: namespace, overlay: overlay
          )
        end

        save_branch(schema_base: schema_base_record, overlays: overlay_records)
      end

      private def save_schema_base(namespace:, schema_base:)
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

      private def save_overlay(namespace:, overlay:)
        hashlink = hashlink_generator.call(overlay)
        record = {
          _id: namespace + '/' + hashlink,
          namespace: namespace,
          DRI: hashlink,
          data: overlay
        }
        es.index(:overlay).bulk_index([record])
        record
      end

      private def save_branch(schema_base:, overlays:)
        namespace = schema_base.fetch(:namespace)
        branch = {
          schema_base: schema_base.fetch(:DRI),
          overlays: overlays.map { |o| o.fetch(:DRI) }.sort
        }
        hashlink = hashlink_generator.call(branch)
        record = {
          _id: namespace + '/' + hashlink,
          namespace: namespace,
          DRI: hashlink,
          data: branch
        }
        es.index(:branch).bulk_index([record])
        record
      end
    end
  end
end
