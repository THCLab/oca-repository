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
          record = by_id(id)
          return unless record
          record[:_source]
        end

        private def by_id(id)
          es.mget(
            %i[schema_base branch].map do |index|
              { _index: index, _id: id }
            end,
            exists: nil
          ).find { |r| r[:found] == true }
        end
      end
    end
  end
end
