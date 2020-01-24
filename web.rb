require 'roda'
require 'stretcher'
require 'json'
require 'plugins/cors'

class Web < Roda
  plugin :json
  plugin :cors

  route do |r|
    if WEBrick::HTTPRequest.const_get('MAX_URI_LENGTH') < 104_857_60
      WEBrick::HTTPRequest.const_set('MAX_URI_LENGTH', 104_857_60)
    end

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
        schema = JSON.parse(r.body.read)

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
