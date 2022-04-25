# frozen_string_literal: true

module V01
  module OCA
    module Services
      class GetSchemasService
        attr_reader :schema_read_repo

        def initialize(schema_read_repo)
          @schema_read_repo = schema_read_repo
        end

        def call(namespace)
          schema_read_repo.find_by_namespace(namespace)
        end
      end
    end
  end
end
