# frozen_string_literal: true

require 'digest/sha2'
require 'base58'
require 'json'

module Schemas
  class HashlinkGenerator
    def self.call(schema)
      Base58.encode(
        Digest::SHA2.hexdigest(
          JSON.generate(schema)
        ).to_i(16)
      )
    end
  end
end
