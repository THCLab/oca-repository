require 'roda'
require 'stretcher'
require 'json'

require './lib/new_record_service'
require './lib/search_service'
require './lib/hashlink_generator'

class Web < Roda
  plugin :json

  route do |r|
    es = Stretcher::Server.new('http://es01:9200')

    r.root do
      'Hello!'
    end

    r.post 'new' do
      return 'Provide "schema" param' unless r.params['schema']
      service = NewRecordService.new(es)

      hashlink = HashlinkGenerator.call(JSON.parse(r.params['schema']))
      service.call(hashlink: hashlink, schema: r.params['schema'])
      hashlink
    end

    r.get 'search' do
      service = SearchService.new(es)
      service.call(r.params['hashlink'], r.params['q'])
    end
  end
end
