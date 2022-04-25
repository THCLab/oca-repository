# frozen_string_literal: true

require 'zip'

module V01
  module OCA
    module Services
      class ImportSchemaChunkService
        attr_reader :schema_write_repo

        def initialize(schema_write_repo)
          @schema_write_repo = schema_write_repo
        end

        def call(namespace, file)
          schema_chunk = JSON.parse(file.read)

          p schema_chunk
          if schema_chunk['type'].include?('/capture_base/')
            schema = { capture_base: schema_chunk }
          elsif schema_chunk['type'].include?('/overlays/')
            schema = { overlays: [schema_chunk] }
          else
            raise 'Invalid file'
          end

          schema_chunk_sai = schema_write_repo.save(
            namespace: namespace, schema: schema
          )
          schema_chunk_sai
        end
      end
    end
  end
end
