# frozen_string_literal: true

require 'base64'
require 'json'

require 'digest/blake3'

module Common
  class SaiGenerator
    def self.call(schema)
      'E' +
        Base64.urlsafe_encode64(
          Digest::BLAKE3.digest(JSON.generate(schema)),
          padding: false
        )
    end
  end
end
