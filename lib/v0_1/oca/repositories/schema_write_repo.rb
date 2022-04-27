# frozen_string_literal: true

require 'moneta'

module V01
  module OCA
    module Repositories
      class SchemaWriteRepo
        attr_reader :es, :hashlink_generator

        def initialize(es, hashlink_generator)
          @es = es
          @hashlink_generator = hashlink_generator
        end

        def save(namespace:, schema:)
          FileUtils.mkdir_p("#{STORAGE_PATH}/namespaces/#{namespace}/db")
          FileUtils.mkdir_p("#{STORAGE_PATH}/oca/db")

          capture_base_sai = save_capture_base(
            namespace: namespace, capture_base: schema.fetch(:capture_base)
          ) if schema[:capture_base]
          return capture_base_sai unless schema[:overlays]

          overlays_sai = []
          schema.fetch(:overlays).each do |overlay|
            overlays_sai << save_overlay(
              namespace: namespace,
              overlay: overlay
            )
          end

          return overlays_sai.first unless schema[:capture_base] && schema[:overlays]

          save_bundle(
            namespace: namespace,
            capture_base_sai: capture_base_sai,
            overlays_sai: overlays_sai,
            schema: schema
          )
        end

        private def save_capture_base(namespace:, capture_base:)
          sai = hashlink_generator.call(capture_base)

          general_store = Moneta.new(:DBM, file: "#{STORAGE_PATH}/oca/db/oca")
          unless general_store.key?(sai)
            create_file(
              path: "#{STORAGE_PATH}/oca",
              filename: sai,
              content: capture_base
            )
            general_store[sai] = JSON.generate({ type: 'capture_base' })
          end
          general_store.close

          store = Moneta.new(:DBM, file: "#{STORAGE_PATH}/namespaces/#{namespace}/db/oca")
          if store.key?(sai)
            store.close
            return sai
          end
          create_file(
            path: "#{STORAGE_PATH}/namespaces/#{namespace}",
            filename: sai,
            content: capture_base
          )
          store[sai] = JSON.generate({ type: 'capture_base' })
          store.close

          sai
        end

        private def save_overlay(namespace:, overlay:)
          sai = hashlink_generator.call(overlay)

          general_store = Moneta.new(:DBM, file: "#{STORAGE_PATH}/oca/db/oca")
          unless general_store.key?(sai)
            create_file(
              path: "#{STORAGE_PATH}/oca",
              filename: sai,
              content: overlay
            )
            general_store[sai] = JSON.generate({ type: 'overlay' })
          end
          general_store.close

          store = Moneta.new(:DBM, file: "#{STORAGE_PATH}/namespaces/#{namespace}/db/oca")
          if store.key?(sai)
            store.close
            return sai
          end
          create_file(
            path: "#{STORAGE_PATH}/namespaces/#{namespace}",
            filename: sai,
            content: overlay
          )
          store[sai] = JSON.generate({ type: 'overlay' })
          store.close

          sai
        end

        private def save_bundle(namespace:, capture_base_sai:, overlays_sai:, schema:)
          branch = {
            capture_base: capture_base_sai,
            overlays: overlays_sai.sort
          }
          sai = hashlink_generator.call(branch)

          general_store = Moneta.new(:DBM, file: "#{STORAGE_PATH}/oca/db/oca")

          unless general_store.key?(sai)
            general_store[sai] = JSON.generate(branch.merge({ type: 'bundle' }))
            general_store.close

            general_bundles_store = Moneta.new(:DBM, file: "#{STORAGE_PATH}/oca/db/cb_bundles")

            general_bundles_store[capture_base_sai] = [] unless general_bundles_store.key?(capture_base_sai)
            general_bundles_store[capture_base_sai] = (general_bundles_store[capture_base_sai] << sai).uniq
            general_bundles_store.close
          end

          store = Moneta.new(:DBM, file: "#{STORAGE_PATH}/namespaces/#{namespace}/db/oca")
          if store.key?(sai)
            store.close
            return sai
          end

          meta_overlays = schema[:overlays].select { |o| o.fetch("type").include? "/meta/" }
          branch_names = meta_overlays.map { |o| o.fetch("name") }.reject(&:empty?)
          branch_descriptions = meta_overlays.map { |o| o.fetch("description") }.reject(&:empty?)

          meta_overlays.each do |meta_overlay|
            overlay_sai = hashlink_generator.call(meta_overlay)
            branch_names = meta_overlays.map { |o| o.fetch("name") }.reject(&:empty?)

            es.create(
              id: "#{namespace}-#{overlay_sai}",
              index: 'meta',
              body: {
                capture_base_sai: meta_overlay.fetch('capture_base'),
                namespace: namespace,
                suggest: [namespace] + meta_overlay.fetch('name').split(/[^a-zA-Z\u0080-\uFFFF]+/),
                name: meta_overlay.fetch('name'),
                description: meta_overlay.fetch('description')
              }
            ) unless es.exists?(index: 'meta', id: "#{namespace}-#{overlay_sai}")
          end

          es.create(
            id: "#{namespace}-#{capture_base_sai}",
            index: 'capture_base',
            body: {
              capture_base_sai: capture_base_sai,
              namespace: namespace,
              attributes: schema[:capture_base].fetch('attributes').keys.map(&:to_s),
              flagged_attributes: schema[:capture_base]['flagged_attributes'] || schema[:capture_base]['pii']
            }
          ) unless es.exists?(index: 'capture_base', id: "#{namespace}-#{capture_base_sai}")

          store[sai] = JSON.generate(branch.merge({ type: 'bundle' }))
          store.close

          bundles_store = Moneta.new(:DBM, file: "#{STORAGE_PATH}/namespaces/#{namespace}/db/cb_bundles")

          bundles_store[capture_base_sai] = [] unless bundles_store.key?(capture_base_sai)
          bundles_store[capture_base_sai] = (bundles_store[capture_base_sai] << sai).uniq
          bundles_store.close

          sai
        end

        private def create_file(path: STORAGE_PATH, filename:, content:)
          FileUtils.mkdir_p(path)
          File.open("#{path}/#{filename}.json", 'w') do |f|
            f.write(JSON.generate(content))
          end
        end
      end
    end
  end
end
