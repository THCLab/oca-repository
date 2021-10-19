# frozen_string_literal: true

module Schemas
  module Repositories
    module V4
      class SchemaWriteRepo
        attr_reader :es, :hashlink_generator

        def initialize(es, hashlink_generator)
          @es = es
          @hashlink_generator = hashlink_generator
        end

        def save(namespace:, schema:)
          capture_base_record = save_capture_base(
            namespace: namespace, capture_base: schema.fetch(:capture_base)
          )
          return capture_base_record unless schema[:overlays]

          overlay_records = []
          schema.fetch(:overlays).each do |overlay|
            overlay_records << save_overlay(
              namespace: namespace, overlay: overlay
            )
          end

          save_branch(capture_base: capture_base_record, overlays: overlay_records)
        end

        private def save_capture_base(namespace:, capture_base:)
          hashlink = hashlink_generator.call(capture_base)
          record = {
            _id: namespace + '/' + hashlink,
            namespace: namespace,
            SAI: hashlink,
            data: capture_base,
            'name-suggest' => [namespace, '_caputure_base_name']
          }
          es.index(:capture_base).bulk_index([record])
          record
        end

        private def save_overlay(namespace:, overlay:)
          hashlink = hashlink_generator.call(overlay)
          record = {
            _id: namespace + '/' + hashlink,
            namespace: namespace,
            SAI: hashlink,
            data: overlay
          }
          es.index(:overlay).bulk_index([record])
          record
        end

        private def save_branch(capture_base:, overlays:)
          namespace = capture_base.fetch(:namespace)
          branch = {
            capture_base: capture_base.fetch(:SAI),
            overlays: overlays.map { |o| o.fetch(:SAI) }.sort
          }
          hashlink = hashlink_generator.call(branch)
          record = {
            _id: namespace + '/' + hashlink,
            namespace: namespace,
            SAI: hashlink,
            data: branch
          }
          es.index(:branch).bulk_index([record])
          record
        end
      end
    end
  end
end
