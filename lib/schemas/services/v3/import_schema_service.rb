# frozen_string_literal: true

require 'zip'

module Schemas
  module Services
    module V3
      class ImportSchemaService
        attr_reader :schema_base_repo, :branch_repo

        def initialize(schema_base_repo, branch_repo)
          @schema_base_repo = schema_base_repo
          @branch_repo = branch_repo
        end

        def call(namespace, raw_params)
          raise "Namespace '_any' is forbidden" if namespace == '_any'

          params = validate(raw_params)
          type = params[:file][:filename].split('.').last
          if type == 'json'
            store_json(namespace, params[:file][:tempfile])
          elsif type == 'zip'
            store_zip(namespace, params[:file][:tempfile])
          else
            raise 'File type must be json or zip'
          end
        end

        def validate(params)
          return unless params['file']
          {
            file: params['file']
          }
        end

        private def store_json(namespace, file)
          schema_base = JSON.parse(file.read)
          saved_schema_base = schema_base_repo.save(
            namespace: namespace, schema_base: schema_base
          )
          saved_schema_base[:DRI]
        end

        private def store_zip(namespace, file)
          branch = extract_zip(file)
          saved_branch = branch_repo.save(
            namespace: namespace, branch: branch
          )
          saved_branch[:DRI]
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
