# frozen_string_literal: true

class Roda
  module RodaPlugins
    module Cors
      module InstanceMethods
        def call(&block)
          if env['REQUEST_METHOD'] == 'OPTIONS'
            [200, {
              'Access-Control-Allow-Headers' => 'Authorization,Content-Type',
              'Access-Control-Allow-Origin' => '*'
            }, ['']]
          else
            response['Access-Control-Allow-Origin'] = '*'
            super
          end
        end
      end
    end

    register_plugin :cors, Cors
  end
end
