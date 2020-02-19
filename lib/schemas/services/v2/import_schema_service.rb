# frozen_string_literal: true

module Schemas
  module Services
    module V2
      class ImportSchemaService
        attr_reader :es, :hashlink_generator

        def initialize(es, hashlink_generator)
          @es = es
          @hashlink_generator = hashlink_generator
        end

        def call(raw_params)
          params = validate(raw_params)
          type = params[:file][:filename].split('.').last
          if type == 'json'
            schema_base = JSON.parse(params[:file][:tempfile].read)
            hashlink = hashlink_generator.call(schema_base)
            es.index(:schema_base).bulk_index([schema_base.merge(_id: hashlink)])
            hashlink
          end
        end

        def validate(params)
          return unless params['file']
          {
            file: params['file']
          }
        end
      end
    end
  end
end
