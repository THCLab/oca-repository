require 'roda'
require 'stretcher'
require 'json'
require 'plugins/cors'
require 'plugins/json_header'

class Web < Roda
  plugin :json
  plugin :json_parser
  plugin :json_header
  plugin :cors

  route do |r|
    es = Stretcher::Server.new('http://es01:9200')

    r.root do
      r.redirect('/schemas')
    end

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
          r.get String do |dri|
            service = Schemas::Services::V2::GetSchemaService.new(es)
            service.call(namespace + '/' + dri)
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
