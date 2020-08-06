# frozen_string_literal: true

require 'roda'
require 'stretcher'
require 'json'
require 'plugins/json_header'

class Web < Roda
  plugin :json
  plugin :json_parser
  plugin :json_header

  route do |r|
    es = Stretcher::Server.new('http://es01:9200')

    r.on 'api' do
      r.on 'schemas' do
        r.get String do |id|
          service = Schemas::Services::GetSchemaService.new(es)
          service.call(id)
        end

        r.get do
          service = Schemas::Services::SearchSchemasService.new(es)
          service.call(r.params)
        end

        r.post do
          service = Schemas::Services::NewSchemaService.new(es)
          schema = r.params

          hashlink = Schemas::HashlinkGenerator.call(schema)
          service.call(hashlink: hashlink, schema: schema)
          hashlink
        end
      end

      r.on 'v2' do
        r.on 'schemas' do
          r.on String do |namespace|
            r.on String do |dri|
              r.on 'archive' do
                r.get do
                  service = Schemas::Services::V2::GenerateArchiveService.new(
                    Schemas::Services::V2::GetSchemaService.new(es),
                    Schemas::HashlinkGenerator
                  )
                  filename, data = service.call(namespace: namespace, dri: dri)

                  response.headers['Content-Disposition'] =
                    "attachment; filename=\"#{filename}\""
                  data
                end
              end

              r.get do
                service = Schemas::Services::V2::GetSchemaService.new(es)
                service.call(namespace + '/' + dri)
              end
            end

            r.get do
              service = Schemas::Services::V2::SearchSchemasService.new(es)
              service.call(r.params.merge(namespace: namespace))
            end

            r.post do
              service = Schemas::Services::V2::ImportSchemaService.new(
                es, ::Schemas::HashlinkGenerator
              )
              dri = service.call(namespace, r.params)

              {
                DRI: dri,
                url: "#{r.base_url}/api/v2/schemas/#{namespace}/#{dri}"
              }
            end
          end

          r.get do
            service = Schemas::Services::V2::SearchSchemasService.new(es)
            service.call(r.params)
          end
        end
      end
    end
  end
end
