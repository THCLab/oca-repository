# frozen_string_literal: true

require 'roda'
require 'stretcher'
require 'json'
require 'plugins/json_header'

class Web < Roda
  plugin :json
  plugin :json_parser
  plugin :json_header

  route do |r|
    es = Stretcher::Server.new('http://es01:9200')

    r.on 'api' do
    end
  end
end
