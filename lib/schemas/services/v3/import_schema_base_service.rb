# frozen_string_literal: true

require 'zip'

module Schemas
  module Services
    module V3
      class ImportSchemaBaseService
        attr_reader :schema_base_repo

        def initialize(schema_base_repo)
          @schema_base_repo = schema_base_repo
        end

        def call(namespace, file)
          schema_base = JSON.parse(file.read)
          saved_schema_base = schema_base_repo.save(
            namespace: namespace, schema_base: schema_base
          )
          saved_schema_base[:DRI]
        end
      end
    end
  end
end
