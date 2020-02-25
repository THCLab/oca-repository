# frozen_string_literal: true

module Schemas
  module Services
    module V2
      class GetSchemaService
        attr_reader :es

        def initialize(es)
          @es = es
        end

        def call(id)
          record = by_id(id, %i[schema_base branch odca])
          return unless record
          if record[:_index] == 'branch'
            resolve_branch(
              record[:_source][:namespace],
              record[:_source][:data]
            )
          else
            record[:_source][:data]
          end
        end

        private def resolve_branch(namespace, branch)
          schema_base_id = namespace + '/' + branch[:schema_base]
          schema_base = by_id(schema_base_id, :schema_base)[:_source][:data]
          overlay_ids = branch[:overlays].map { |id| namespace + '/' + id }
          overlays = by_ids(overlay_ids, :overlay).map { |r| r[:_source][:data] }
          {
            schema_base: schema_base,
            overlays: overlays
          }
        end

        private def by_id(id, indexes)
          by_ids([id], indexes).first
        end

        private def by_ids(ids, indexes)
          indexes = [indexes] unless indexes.is_a? Array
          docs = indexes.map do |index|
            ids.map do |id|
              { _index: index, _id: id }
            end
          end.flatten
          es.mget(docs, exists: nil)
            .select { |r| r[:found] == true }
        end
      end
    end
  end
end
