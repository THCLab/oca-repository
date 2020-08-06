# frozen_string_literal: true

require 'zip'

module Schemas
  module Services
    module V2
      class ImportSchemaService
        attr_reader :es, :hashlink_generator

        def initialize(es, hashlink_generator)
          @es = es
          @hashlink_generator = hashlink_generator
        end

        def call(namespace, raw_params)
          params = validate(raw_params)
          type = params[:file][:filename].split('.').last
          if type == 'json'
            store_json(namespace, params[:file][:tempfile])
          elsif type == 'zip'
            store_zip(namespace, params[:file][:tempfile])
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
          hashlink = hashlink_generator.call(schema_base)
          record = {
            _id: namespace + '/' + hashlink,
            namespace: namespace,
            DRI: hashlink,
            data: schema_base
          }
          es.index(:schema_base).bulk_index([record])
          hashlink
        end

        private def store_zip(namespace, file)
          schema = extract_zip(file)

          es.index(:schema_base).bulk_index(
            schema[:schema_base].map do |hashlink, content|
              {
                _id: namespace + '/' + hashlink,
                namespace: namespace,
                DRI: hashlink,
                data: content,
                'name-suggest' => [namespace, content['name']]
              }
            end
          )
          es.index(:overlay).bulk_index(
            schema[:overlay].map do |hashlink, content|
              {
                _id: namespace + '/' + hashlink,
                namespace: namespace,
                DRI: hashlink,
                data: content
              }
            end
          )

          branch = {
            schema_base: schema[:schema_base].keys.first,
            overlays: schema[:overlay].keys.sort
          }
          branch_hashlink = hashlink_generator.call(branch)
          branch_record = {
            _id: namespace + '/' + branch_hashlink,
            namespace: namespace,
            DRI: branch_hashlink,
            data: branch
          }
          es.index(:branch).bulk_index([branch_record])
          branch_hashlink
        end

        private def extract_zip(file)
          schema = { overlay: {} }
          Zip::File.open(file) do |zip|
            zip.each do |entry|
              next unless entry.ftype == :file
              content = JSON.parse(entry.get_input_stream.read)
              hashlink = hashlink_generator.call(content)
              type = entry.name.split('/').size == 1 ? :schema_base : :overlay
              if type == :schema_base
                schema[:schema_base] = { hashlink => content }
              elsif type == :overlay
                schema[:overlay].merge!(hashlink => content)
              end
            end
          end
          schema
        end
      end
    end
  end
end
