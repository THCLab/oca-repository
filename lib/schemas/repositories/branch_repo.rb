# frozen_string_literal: true

module Schemas
  module Repositories
    class BranchRepo
      attr_reader :es, :hashlink_generator, :schema_base_repo

      def initialize(es, hashlink_generator, schema_base_repo)
        @es = es
        @hashlink_generator = hashlink_generator
        @schema_base_repo = schema_base_repo
      end

      def save(namespace:, branch:)
        schema_base_record = schema_base_repo.save(branch.fetch(:schema_base))
        overlay_records = []
        branch.fetch(:overlays).each do |overlay|
          overlay_records << save_overlay(namespace: namespace, overlay: overlay)
        end

        save_branch(schema_base: schema_base_record, overlays: overlay_records)
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
        branch = {
          schema_base: schema_base[:DRI],
          overlays: overlays.map(o => o[:DRI])
        }
        hashlink = hashlink_generator.call(branch)
        record = {
          _id: namespace + '/' + hashlink,
          namespace: namespace,
          DRI: branch_hashlink,
          data: branch
        }
        es.index(:branch).bulk_index([record])
        record
      end
    end
  end
end
