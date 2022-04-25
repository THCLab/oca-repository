# frozen_string_literal: true

require 'moneta'

module V01
  module Transformations
    module Units
      module Services
        class ImportService
          def call(raw_params)
            params = validate(raw_params)
            FileUtils.mkdir_p("#{STORAGE_PATH}/transformations/units")

            store = Moneta.new(:DBM, file: "#{STORAGE_PATH}/transformations/units/#{params[:table]}")
            raise "key '#{params[:key]}' is already set in '#{params[:table]}' table" if store.key?(params[:key])

            store[params[:key]] = params[:value]
            store.close
          end

          def validate(params)
            missing = []
            %w[table key value].each do |required_key|
              missing << required_key unless params[required_key]
            end

            raise "missing keys: #{missing}" unless missing.empty?

            {
              table: params['table'],
              key: params['key'],
              value: params['value']
            }
          end
        end
      end
    end
  end
end
