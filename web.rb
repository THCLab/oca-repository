# frozen_string_literal: true

require 'roda'
require 'json'
require 'plugins/json_header'
require 'elasticsearch'

class Web < Roda
  plugin :json
  plugin :json_parser
  plugin :json_header

  route do |r|
    base_url = ENV['BASE_URL'] || r.base_url
    es = Elasticsearch::Client.new(host: ES_URL)

    r.on 'api' do
    end
  end
end
