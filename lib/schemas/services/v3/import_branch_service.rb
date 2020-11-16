# frozen_string_literal: true

require 'zip'

module Schemas
  module Services
    module V3
      class ImportBranchService
        attr_reader :schema_repo

        def initialize(schema_repo)
          @schema_repo = schema_repo
        end

        def call(namespace, file)
          schema = extract_zip(file)
          saved_schema = schema_repo.save(namespace: namespace, schema: schema)
          saved_schema[:DRI]
        end

        private def extract_zip(file)
          schema = { overlays: [] }
          Zip::File.open(file) do |zip|
            zip.each do |entry|
              next unless entry.ftype == :file
              content = JSON.parse(entry.get_input_stream.read)
              type = entry.name.split('/').size == 1 ? :schema_base : :overlay
              if type == :schema_base
                schema[:schema_base] = content
              elsif type == :overlay
                schema[:overlays].push(content)
              end
            end
          end
          schema
        end
      end
    end
  end
end
