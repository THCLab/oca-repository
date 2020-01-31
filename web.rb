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

    r.get 'api' do
      r.redirect('http://localhost:8000')
    end
  end
end
