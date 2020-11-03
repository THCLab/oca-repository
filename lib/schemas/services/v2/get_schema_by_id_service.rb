# frozen_string_literal: true

module Schemas
  module Services
    module V2
      class GetSchemaByIdService
        attr_reader :es

        def initialize(es)
          @es = es
        end

        def call(id)
          by_id(id, %i[schema_base overlay branch odca])
        end

        def by_id(id, indexes)
          by_ids([id], indexes).first
        end

        def by_ids(ids, indexes)
          indexes = [indexes] unless indexes.is_a? Array
          docs = indexes.map do |index|
            ids.map do |id|
              { _index: index, _id: id }
            end
          end.flatten
          es.mget(docs, exists: nil)
            .select { |r| r[:found] == true }
        end
      end
    end
  end
end
