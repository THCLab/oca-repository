# frozen_string_literal: true

module Schemas
  module Services
    module V3
      class SearchSchemasService
        attr_reader :schema_read_repo

        def initialize(schema_read_repo)
          @schema_read_repo = schema_read_repo
        end

        def call(raw_params)
          params = validate(raw_params)
          if params[:suggestion]
            schema_read_repo.search_by_suggestion(params.fetch(:suggestion))
          else
            schema_read_repo.search(
              namespace: params.fetch(:namespace),
              query: params.fetch(:query),
              type: params.fetch(:type),
              limit: params.fetch(:limit) || 1000
            )
          end
        rescue
          []
        end

        private def validate(raw_params)
          limit = begin
                    Integer(raw_params['limit'])
                  rescue
                    nil
                  end

          {
            namespace: raw_params['namespace'],
            suggestion: raw_params['suggest'],
            query: raw_params['q'],
            type: raw_params['type'],
            limit: limit
          }
        end
      end
    end
  end
end
