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
          record = by_id(id, %i[schema_base branch])
          return unless record
          if record[:_index] == 'schema_base'
            record[:_source]
          elsif record[:_index] == 'branch'
            resolve_branch(record[:_source])
          end
        end

        private def resolve_branch(branch)
          schema_base = by_id(branch[:schema_base], :schema_base)[:_source]
          overlays = by_ids(branch[:overlays], :overlay).map { |r| r[:_source] }
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
