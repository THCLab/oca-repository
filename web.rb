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
      r.on 'v0.1' do
        r.on 'schemas' do
          r.on String do |sai|
            r.on 'bundles' do
              service = ::V01::OCA::Services::GetSchemaBundlesService.new
              service.call(namespace: nil, sai:)
            end

            r.on 'archive' do
              schema_read_repo = ::V01::OCA::Repositories::SchemaReadRepo.new(es)
              service = ::V01::OCA::Services::GenerateArchiveService.new(
                ::V01::OCA::Services::GetSchemaService.new(schema_read_repo),
                ::Common::SaiGenerator
              )
              filename, data = service.call(nil, sai)

              response.headers['Content-Disposition'] =
                "attachment; filename=\"#{filename}\""
              data
            end

            r.get do
              schema_read_repo = ::V01::OCA::Repositories::SchemaReadRepo.new(es)
              service = ::V01::OCA::Services::GetSchemaService.new(
                schema_read_repo
              )
              service.call(namespace: nil, sai:)
            end
          end

          r.get do
            schema_read_repo = ::V01::OCA::Repositories::SchemaReadRepo.new(es)
            service = ::V01::OCA::Services::GetSchemasService.new(
              schema_read_repo
            )
            service.call(nil)
          end
        end

        r.on 'namespaces' do
          r.on String do |namespace|
            r.on 'schemas' do
              r.on String do |sai|
                r.on 'bundles' do
                  service = ::V01::OCA::Services::GetSchemaBundlesService.new
                  service.call(namespace:, sai:)
                end

                r.on 'archive' do
                  schema_read_repo = ::V01::OCA::Repositories::SchemaReadRepo.new(es)
                  service = ::V01::OCA::Services::GenerateArchiveService.new(
                    ::V01::OCA::Services::GetSchemaService.new(schema_read_repo),
                    ::Common::SaiGenerator
                  )
                  filename, data = service.call(namespace, sai)

                  response.headers['Content-Disposition'] =
                    "attachment; filename=\"#{filename}\""
                  data
                end

                r.get do
                  schema_read_repo = ::V01::OCA::Repositories::SchemaReadRepo.new(es)
                  service = ::V01::OCA::Services::GetSchemaService.new(
                    schema_read_repo
                  )
                  service.call(namespace:, sai:)
                end
              end

              r.get do
                schema_read_repo = ::V01::OCA::Repositories::SchemaReadRepo.new(es)
                service = ::V01::OCA::Services::GetSchemasService.new(
                  schema_read_repo
                )
                service.call(namespace)
              end

              r.post do
                schema_write_repo = ::V01::OCA::Repositories::SchemaWriteRepo.new(
                  es, ::Common::SaiGenerator
                )
                service = ::V01::OCA::Services::ImportSchemaService.new(
                  ::V01::OCA::Services::ImportSchemaChunkService.new(
                    schema_write_repo
                  ),
                  ::V01::OCA::Services::ImportBranchService.new(schema_write_repo)
                )
                begin
                  sai = service.call(namespace, r.params)

                  {
                    success: true,
                    SAI: sai,
                    path: URI.join(base_url, "api/v0.1/namespaces/#{namespace}/schemas/#{sai}")
                  }
                rescue StandardError => e
                  puts e.backtrace
                  {
                    success: false,
                    errors: [e.message],
                    path: URI.join(base_url, 'api/v0.1/schemas')
                  }
                end
              end
            end
          end
        end

        r.on 'search' do
          schema_read_repo = ::V01::OCA::Repositories::SchemaReadRepo.new(es)
          service = ::V01::OCA::Services::SearchSchemasService.new(
            schema_read_repo
          )
          service.call(r.params)
        end

        r.on 'transformations' do
          r.on 'units' do
            r.get do
              service = ::V01::Transformations::Units::Services::GetFormulaService.new
              result = service.call(r.params)
              { success: true, result: }

              rescue StandardError => e
                { success: false, error: e }
            end

            r.post do
              service = ::V01::Transformations::Units::Services::ImportService.new
              service.call(r.params)

              { success: true }

              rescue StandardError => e
                { success: false, error: e }
            end
          end
        end
      end
    end
  end
end
