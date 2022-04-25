# frozen_string_literal: true

module V01
  module OCA
    module Services
      class GetSchemaService
        attr_reader :schema_read_repo

        def initialize(schema_read_repo)
          @schema_read_repo = schema_read_repo
        end

        def call(namespace:, sai:)
          schema_read_repo.find_by_namespace_sai(namespace: namespace, sai: sai)
        end
      end
    end
  end
end
