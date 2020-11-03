# frozen_string_literal: true

module Schemas
  module Services
    module V2
      class GetSchemaService
        attr_reader :es

        def initialize(es)
          @es = es
        end

        def call(namespace:, dri:)
          record = if namespace == '_any'
                     get_schema_by_dri_service.call(dri)
                   else
                     get_schema_by_id_service.call(namespace + '/' + dri)
                   end

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

        private def get_schema_by_id_service
          @get_schema_by_id_service ||= Schemas::Services::V2::GetSchemaByIdService.new(es)
        end

        private def get_schema_by_dri_service
          @get_schema_by_dri_service ||= Schemas::Services::V2::GetSchemaByDriService.new(es)
        end

        private def resolve_branch(namespace, branch)
          schema_base_id = namespace + '/' + branch[:schema_base]
          schema_base = get_schema_by_id_service.by_id(schema_base_id, :schema_base)[:_source][:data]
          overlay_ids = branch[:overlays].map { |id| namespace + '/' + id }
          overlays = get_schema_by_id_service.by_ids(overlay_ids, :overlay).map { |r| r[:_source][:data] }
          {
            schema_base: schema_base,
            overlays: overlays
          }
        end
      end
    end
  end
end
