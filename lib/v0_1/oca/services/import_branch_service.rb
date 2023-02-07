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
          schema = compose_schema(extract_zip(file))
          schema_sai = schema_write_repo.save(namespace: namespace, schema: schema)
          schema_sai
        end

        private def compose_schema(extracted_files)
          reference_cb_sais = extracted_files['meta']['files'].entries
            .map { |e| e[0] }
          root_cb_sai = reference_cb_sais.delete(extracted_files['meta']['root'])
          schema = fetch_oca(extracted_files, root_cb_sai)
          return schema if reference_cb_sais.empty?

          references = reference_cb_sais.each_with_object({}) do |sai, memo|
            memo[sai] = fetch_oca(extracted_files, sai)
            memo
          end

          schema.merge({ references: })
        end

        private def fetch_oca(files, capture_base_sai)
          {
            capture_base: files[capture_base_sai],
            overlays: files.entries.map { |e| e[1] }.select { |ov| ov['capture_base'] == capture_base_sai }
          }
        end

        private def extract_zip(file)
          files = {}
          Zip::File.open(file) do |zip|
            zip.each do |entry|
              name, type = entry.name.split('.')
              next unless type == 'json'

              content = JSON.parse(entry.get_input_stream.read)
              files[name] = content
            end
          end
          files
        end
      end
    end
  end
end
