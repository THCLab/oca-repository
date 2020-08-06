# frozen_string_literal: true

require 'zip'

module Schemas
  module Services
    module V2
      class GenerateArchiveService
        attr_reader :get_schema_service, :hashlink_generator

        def initialize(get_schema_service, hashlink_generator)
          @get_schema_service = get_schema_service
          @hashlink_generator = hashlink_generator
        end

        def call(namespace:, dri:)
          schema = get_schema_service.call(namespace + '/' + dri)
          if schema[:overlays]
            filename = dri + '.zip'
            data = pack_to_zip(schema)
            [filename, data]
          else
            file = File.new(dri + '.json', 'w+')
            File.open(file, 'w') do |f|
              f.write(JSON.pretty_generate(schema))
            end
            [file.path, file.read]
          end
        end

        private def pack_to_zip(schema)
          schema_base, overlays, schema_name = destruct_schema(schema)
          io_stream = Zip::OutputStream.write_buffer do |zio|
            zio.put_next_entry("#{schema_name}/")
            zio.put_next_entry(schema_name + '.json')
            zio.write(JSON.pretty_generate(schema_base))
            overlays.each do |overlay|
              zio.put_next_entry("#{schema_name}/#{overlay_filename(overlay)}")
              zio.write(JSON.pretty_generate(overlay))
            end
          end
          io_stream.string
        end

        private def destruct_schema(schema)
          [
            schema[:schema_base],
            schema[:overlays],
            schema[:schema_base][:name]
          ]
        end

        private def overlay_filename(overlay)
          overlay_dri = hashlink_generator.call(overlay)
          "#{map_type(overlay)}-hl:#{overlay_dri}.json"
        end

        private def map_type(overlay)
          overlay[:type].split('/')[2]
            .split('_').map(&:capitalize).join + 'Overlay'
        end
      end
    end
  end
end
