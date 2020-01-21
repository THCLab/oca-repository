require 'roda'
require 'stretcher'

require './lib/new_record_service'
require './lib/search_service'

class Web < Roda
  plugin :json

  route do |r|
    es = Stretcher::Server.new('http://es01:9200')

    r.root do
      'Hello!'
    end

    r.post 'new' do
      return 'Provide "filename" param' unless r.params['filename']
      return 'Provide "json" param' unless r.params['json']
      service = NewRecordService.new(es)
      service.call(filename: r.params['filename'], json: r.params['json'])
    end

    r.get 'search' do
      service = SearchService.new(es)
      service.call(r.params['q'])
    end
  end
end
