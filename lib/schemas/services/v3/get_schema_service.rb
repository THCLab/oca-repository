# frozen_string_literal: true

module Schemas
  module Services
    module V3
      class GetSchemaService
        attr_reader :schema_read_repo

        def initialize(schema_read_repo)
          @schema_read_repo = schema_read_repo
        end

        def call(dri)
          schema_read_repo.find_by_dri(dri)
        end
      end
    end
  end
end
