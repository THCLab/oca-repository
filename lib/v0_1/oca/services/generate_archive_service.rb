# frozen_string_literal: true

require 'zip'
require 'moneta'

module V01
  module OCA
    module Services
      class GenerateArchiveService
        attr_reader :get_schema_service, :hashlink_generator

        def initialize(get_schema_service, hashlink_generator)
          @get_schema_service = get_schema_service
          @hashlink_generator = hashlink_generator
        end

        def call(namespace, sai)
          oca_storage_path = namespace ? "#{STORAGE_PATH}/namespaces/#{namespace}" : "#{STORAGE_PATH}/oca"
          schema = get_schema_service.call(namespace: namespace, sai: sai)

          store = Moneta.new(:DBM, file: "#{oca_storage_path}/db/oca")
          type = JSON.parse(store[sai])['type']
          store.close

          if type == 'bundle'
            filename = sai + '.zip'
            data = pack_to_zip(schema)
            [filename, data]
          else
            file = File.new(sai + '.json', 'w+')
            File.open(file, 'w') do |f|
              f.write(JSON.generate(schema))
            end
            [file.path, file.read]
          end
        end

        private def pack_to_zip(schema)
          capture_base, overlays, references = destruct_schema(schema)
          capture_base_sai = hashlink_generator.call(capture_base)

          meta = { root: capture_base_sai, files: {} }
          meta[:files]["capture_base-0"] = capture_base_sai

          io_stream = Zip::OutputStream.write_buffer do |zio|
            zio.put_next_entry(capture_base_sai + '.json')
            zio.write(JSON.generate(capture_base))
            overlays.each do |overlay|
              overlay_sai = hashlink_generator.call(overlay)
              meta[:files][parse_meta_key(overlay)] = overlay_sai
              zio.put_next_entry("#{overlay_sai}.json")
              zio.write(JSON.generate(overlay))
            end

            if references
              references.entries.map { |e| e[1] }.each_with_index do |reference, i|
                cb_sai = hashlink_generator.call(reference[:capture_base])
                meta[:files]["capture_base-#{i + 1}"] = cb_sai
                zio.put_next_entry("#{cb_sai}.json")
                zio.write(JSON.generate(reference[:capture_base]))
                reference[:overlays].each do |overlay|
                  overlay_sai = hashlink_generator.call(overlay)
                  meta[:files][parse_meta_key(overlay)] = overlay_sai
                  zio.put_next_entry("#{overlay_sai}.json")
                  zio.write(JSON.generate(overlay))
                end
              end
            end

            zio.put_next_entry('meta.json')
            zio.write(JSON.pretty_generate(meta))
          end
          io_stream.string
        end

        private def parse_meta_key(overlay)
          language = overlay['language']
          overlay_type = overlay['type'].split('/')[2]
          key = "[#{overlay['capture_base']}] #{overlay_type}"

          return key unless language
          key += " (#{language})"

          key
        end

        private def destruct_schema(schema)
          [
            schema[:capture_base],
            schema[:overlays],
            schema[:references]
          ]
        end
      end
    end
  end
end
