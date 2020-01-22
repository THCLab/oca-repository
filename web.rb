require 'roda'
require 'stretcher'
require 'json'

class Web < Roda
  plugin :json

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
        service.call(r.params['q'])
      end

      r.post 'new' do
        return 'Provide "schema" param' unless r.params['schema']
        service = Schemas::Services::NewSchemaService.new(es)

        hashlink = Schemas::HashlinkGenerator.call(
          JSON.parse(r.params['schema'])
        )
        service.call(hashlink: hashlink, schema: r.params['schema'])
        hashlink
      end
    end
  end
end
