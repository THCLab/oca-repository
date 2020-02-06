# frozen_string_literal: true

class Roda
  module RodaPlugins
    module JsonHeader
      module InstanceMethods
        def call(&block)
          super unless env['REQUEST_METHOD'] == 'POST'

          body = env['rack.input'].read
          env['CONTENT_TYPE'] = 'application/json' if valid_json?(body)
          super
        end

        private def valid_json?(json)
          JSON.parse(json)
          true
        rescue JSON::ParserError
          false
        end
      end
    end

    register_plugin :json_header, JsonHeader
  end
end
