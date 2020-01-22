require 'roda'
require 'stretcher'
require 'json'

require './lib/new_schema_service'
require './lib/search_schemas_service'
require './lib/get_schema_service'
require './lib/hashlink_generator'

class Web < Roda
  plugin :json

  route do |r|
    es = Stretcher::Server.new('http://es01:9200')

    r.root do
      r.redirect('/schemas')
    end

    r.on 'schemas' do
      r.get String do |id|
        service = GetSchemaService.new(es)
        service.call(id)
      end

      r.get do
        service = SearchSchemasService.new(es)
        service.call(r.params['q'])
      end

      r.post 'new' do
        return 'Provide "schema" param' unless r.params['schema']
        service = NewSchemaService.new(es)

        hashlink = HashlinkGenerator.call(JSON.parse(r.params['schema']))
        service.call(hashlink: hashlink, schema: r.params['schema'])
        hashlink
      end
    end
  end
end
