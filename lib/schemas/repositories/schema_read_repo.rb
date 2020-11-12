# frozen_string_literal: true

module Schemas
  module Repositories
    class SchemaReadRepo
      attr_reader :es

      INDEXES = %i[schema_base overlay branch odca]

      def initialize(es)
        @es = es
      end

      def find_by_dri(dri)
        query = { bool: { must: [{ match: { DRI: dri } }] } }
        record = es.msearch([{ index: INDEXES }, { query: query }])
          .first.results.first

        return record[:_source][:data] unless record[:_index] == 'branch'

        resolve_branch(record)
      end

      private def resolve_branch(record)
        namespace = record[:_source][:namespace]
        branch = record[:_source][:data]

        schema_base_id = namespace + '/' + branch[:schema_base]
        schema_base = by_id(schema_base_id, :schema_base)[:_source][:data]

        overlay_ids = branch[:overlays].map { |dri| namespace + '/' + dri }
        overlays = by_ids(overlay_ids, :overlay).map { |r| r[:_source][:data] }

        { schema_base: schema_base, overlays: overlays }
      end

      private def by_id(id, index)
        by_ids([id], :schema_base).first
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
