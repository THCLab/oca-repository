require 'yaml'
require 'stretcher'

Dir["#{LIB_PATH}/schemas/*.rb"].each { |file| require file }
Dir["#{LIB_PATH}/schemas/repositories/*.rb"].each { |file| require file }
Dir["#{LIB_PATH}/schemas/services/*.rb"].each { |file| require file }
Dir["#{LIB_PATH}/schemas/services/v1/*.rb"].each { |file| require file }
Dir["#{LIB_PATH}/schemas/services/v2/*.rb"].each { |file| require file }
Dir["#{LIB_PATH}/schemas/services/v3/*.rb"].each { |file| require file }

es_config = YAML.load_file("#{ROOT_PATH}/config/elastic_search.yml")
es = Stretcher::Server.new('http://es01:9200')
es_updated = false

until es_updated
  begin
    es_config.each do |index, settings|
      es.index(index).update_settings(settings)
    end
    es_updated = true
  rescue Faraday::Error::ConnectionFailed
    sleep 1
  rescue Faraday::Error::TimeoutError
    sleep 1
  rescue Stretcher::RequestError::NotFound => e
    es.index(e.http_response.env[:body]['error']['index']).create
  end
end
