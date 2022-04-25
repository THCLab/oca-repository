# frozen_string_literal: true

require 'yaml'
require 'elasticsearch'

Dir["#{LIB_PATH}/common/*.rb"].sort.each { |file| require file }

Dir["#{LIB_PATH}/v0_1/*.rb"].sort.each { |file| require file }
Dir["#{LIB_PATH}/v0_1/oca/*.rb"].sort.each { |file| require file }
Dir["#{LIB_PATH}/v0_1/oca/repositories/*.rb"].sort.each { |file| require file }
Dir["#{LIB_PATH}/v0_1/oca/services/*.rb"].sort.each { |file| require file }
Dir["#{LIB_PATH}/v0_1/transformations/*.rb"].sort.each { |file| require file }
Dir["#{LIB_PATH}/v0_1/transformations/units/*.rb"].sort.each { |file| require file }
Dir["#{LIB_PATH}/v0_1/transformations/units/services/*.rb"].sort.each { |file| require file }

raise 'Please provide ES_URL environment variable.' unless ENV['ES_URL']

ES_URL = URI(ENV['ES_URL']).normalize.to_s
STORAGE_PATH = File.join(ROOT_PATH, 'storage')

es_config = YAML.load_file("#{ROOT_PATH}/config/elastic_search.yml")
es = Elasticsearch::Client.new(host: ES_URL)
indexes_updated = 0

until indexes_updated >= es_config.size
  begin
    es.cluster.health
    es_config.each do |index, config|
      indexes_updated += 1
      next if es.indices.exists?(index: index)

      es.indices.create(index: index, body: config)
    end
  rescue Faraday::ConnectionFailed
    sleep 10
  rescue Faraday::TimeoutError
    sleep 10
  end
end
