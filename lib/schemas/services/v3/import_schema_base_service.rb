# frozen_string_literal: true

require 'zip'

module Schemas
  module Services
    module V3
      class ImportSchemaBaseService
        attr_reader :schema_repo

        def initialize(schema_repo)
          @schema_repo = schema_repo
        end

        def call(namespace, file)
          schema_base = JSON.parse(file.read)
          schema = { schema_base: schema_base }
          saved_schema_base = schema_repo.save(
            namespace: namespace, schema: schema
          )
          saved_schema_base[:DRI]
        end
      end
    end
  end
end
