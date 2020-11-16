# frozen_string_literal: true

require 'zip'

module Schemas
  module Services
    module V3
      class ImportSchemaService
        attr_reader :import_schema_base_service, :import_branch_service

        def initialize(import_schema_base_service, import_branch_service)
          @import_schema_base_service = import_schema_base_service
          @import_branch_service = import_branch_service
        end

        def call(namespace, raw_params)
          params = validate(raw_params)
          type = params[:file][:filename].split('.').last
          if type == 'json'
            import_schema_base_service.call(namespace, params[:file][:tempfile])
          elsif type == 'zip'
            import_branch_service.call(namespace, params[:file][:tempfile])
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
      end
    end
  end
end
