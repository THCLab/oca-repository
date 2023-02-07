# frozen_string_literal: true

require 'base64'
require 'json'

require 'digest/blake3'

module Common
  class SaiGenerator
    def self.call(schema)
      schema_tmp = schema.clone
      schema_tmp['digest'] = '############################################' if schema_tmp['digest']

      'E' +
        Base64.urlsafe_encode64(
          Digest::BLAKE3.digest(JSON.generate(schema_tmp)),
          padding: false
        )
    end
  end
end
