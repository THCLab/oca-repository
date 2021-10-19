# frozen_string_literal: true

require 'zip'

module Schemas
  module Services
    module V4
      class GenerateArchiveService
        attr_reader :get_schema_service, :hashlink_generator

        def initialize(get_schema_service, hashlink_generator)
          @get_schema_service = get_schema_service
          @hashlink_generator = hashlink_generator
        end

        def call(sai)
          schema = get_schema_service.call(sai)
          if schema[:overlays]
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
          capture_base, overlays = destruct_schema(schema)
          capture_base_sai = hashlink_generator.call(capture_base)

          io_stream = Zip::OutputStream.write_buffer do |zio|
            zio.put_next_entry("#{capture_base_sai}/")
            zio.put_next_entry(capture_base_sai + '.json')
            zio.write(JSON.generate(capture_base))
            overlays.each do |overlay|
              overlay_sai = hashlink_generator.call(overlay)
              zio.put_next_entry("#{capture_base_sai}/#{overlay_sai}.json")
              zio.write(JSON.generate(overlay))
            end
          end
          io_stream.string
        end

        private def destruct_schema(schema)
          [
            schema[:capture_base],
            schema[:overlays]
          ]
        end
      end
    end
  end
end
