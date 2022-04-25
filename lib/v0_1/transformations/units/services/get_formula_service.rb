# frozen_string_literal: true

require 'moneta'

module V01
  module Transformations
    module Units
      module Services
        class GetFormulaService
          def call(raw_params)
            params = validate(raw_params)
            source = {
              metric_system: params[:source].split(':').first,
              unit: params[:source].split(':').last
            }
            target = {
              metric_system: params[:target].split(':').first,
              unit: params[:target].split(':').last
            }

            types_store = Moneta.new(:DBM, file: "#{STORAGE_PATH}/transformations/units/types")
            raise "Unknown unit: #{params[:source]}" unless types_store.key?(params[:source])
            raise "Unknown unit: #{params[:target]}" unless types_store.key?(params[:target])

            source[:type] = types_store[params[:source]]
            target[:type] = types_store[params[:target]]
            types_store.close

            if source[:type] != target[:type]
              raise "Can't convert #{source[:type]} (#{params[:source]}) to #{target[:type]}(#{params[:target]})"
            end

            base_units_store = Moneta.new(:DBM, file: "#{STORAGE_PATH}/transformations/units/base")
            unless base_units_store.key?("#{source[:type]}:#{source[:metric_system]}")
              raise "Undefined base unit for #{source[:type]}:#{source[:metric_system]}"
            end
            unless base_units_store.key?("#{target[:type]}:#{target[:metric_system]}")
              raise "Undefined base unit for #{target[:type]}:#{target[:metric_system]}"
            end

            source[:base_unit] = base_units_store["#{source[:type]}:#{source[:metric_system]}"]
            target[:base_unit] = base_units_store["#{target[:type]}:#{target[:metric_system]}"]
            base_units_store.close

            to_base_multipliers_store = Moneta.new(
              :DBM, file: "#{STORAGE_PATH}/transformations/units/to_base_multipliers"
            )
            unless to_base_multipliers_store.key?("#{source[:metric_system]}:#{source[:type]}:#{source[:unit]}")
              raise "Undefined base muliplier for #{params[:source]}"
            end
            unless to_base_multipliers_store.key?("#{target[:metric_system]}:#{target[:type]}:#{target[:unit]}")
              raise "Undefined base muliplier for #{params[:target]}"
            end

            source[:to_base_multiplier] =
              to_base_multipliers_store["#{source[:metric_system]}:#{source[:type]}:#{source[:unit]}"].to_f
            target[:to_base_multiplier] =
              to_base_multipliers_store["#{target[:metric_system]}:#{target[:type]}:#{target[:unit]}"].to_f
            to_base_multipliers_store.close

            conversion_formula_key =
              "#{source[:metric_system]}:#{source[:base_unit]}->#{target[:metric_system]}:#{target[:base_unit]}"
            conversion_formula_reversed_key =
              "#{target[:metric_system]}:#{target[:base_unit]}->#{source[:metric_system]}:#{source[:base_unit]}"
            conversion_formulas_store =
              Moneta.new(:DBM, file: "#{STORAGE_PATH}/transformations/units/conversion_formulas")

            unless conversion_formulas_store.key?(conversion_formula_key) ||
                conversion_formulas_store.key?(conversion_formula_reversed_key)
              raise "Can't find conversion formula for '#{conversion_formula_key}'"
            end

            reversed = false
            conversion_formula =
              if conversion_formulas_store.key?(conversion_formula_key)
                JSON.parse(conversion_formulas_store[conversion_formula_key])
              else
                reversed = true
                JSON.parse(conversion_formulas_store[conversion_formula_reversed_key])
              end

            conversion_formulas_store.close

            formula = []
            if reversed
              formula << { 'op' => '*', 'value' => target[:to_base_multiplier] }
              formula += conversion_formula
              formula << { 'op' => '/', 'value' => source[:to_base_multiplier] }
            else
              formula << { 'op' => '*', 'value' => source[:to_base_multiplier] }
              formula += conversion_formula
              formula << { 'op' => '/', 'value' => target[:to_base_multiplier] }
            end

            reversed_formula = reverse_formula(formula)

            {
              "#{params[:source]}->#{params[:target]}" =>
                reversed ? reversed_formula : formula,
              "#{params[:target]}->#{params[:source]}" =>
                reversed ? formula : reversed_formula
            }
          end

          def validate(params)
            missing = []
            %w[source target].each do |required_key|
              missing << required_key unless params[required_key]
            end

            raise "missing keys: #{missing}" unless missing.empty?

            {
              source: params['source'],
              target: params['target']
            }
          end

          def reverse_formula(formula)
            operations_reverse_table = {
              '+' => '-',
              '-' => '+',
              '*' => '/',
              '/' => '*'
            }
            formula.reverse.each_with_object([]) do |operation, result|
              result << {
                'op' => operations_reverse_table[operation['op']],
                'value' => operation['value']
              }
            end
          end
        end
      end
    end
  end
end
