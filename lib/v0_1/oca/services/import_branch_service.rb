# frozen_string_literal: true

require 'zip'

module V01
  module OCA
    module Services
      class ImportBranchService
        attr_reader :schema_write_repo

        def initialize(schema_write_repo)
          @schema_write_repo = schema_write_repo
        end

        def call(namespace, file)
          schema = extract_zip(file)
          schema_sai = schema_write_repo.save(namespace: namespace, schema: schema)
          schema_sai
        end

        private def extract_zip(file)
          schema = { overlays: [] }
          Zip::File.open(file) do |zip|
            zip.each do |entry|
              next unless entry.ftype == :file
              content = JSON.parse(entry.get_input_stream.read)
              type = entry.name.split('/').size == 1 ? :capture_base : :overlay
              if type == :capture_base
                schema[:capture_base] = content
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
