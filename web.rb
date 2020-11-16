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
      r.on 'schemas' do
        r.get String do |id|
          service = Schemas::Services::V1::GetSchemaService.new(es)
          service.call(id)
        end

        r.get do
          service = Schemas::Services::V1::SearchSchemasService.new(es)
          service.call(r.params)
        end

        r.post do
          service = Schemas::Services::V1::NewSchemaService.new(es)
          schema = r.params

          hashlink = Schemas::HashlinkGenerator.call(schema)
          service.call(hashlink: hashlink, schema: schema)
          hashlink
        end
      end

      r.on 'v2' do
        r.on 'schemas' do
          r.on String do |namespace|
            r.on String do |dri|
              r.on 'archive' do
                r.get do
                  service = Schemas::Services::V2::GenerateArchiveService.new(
                    Schemas::Services::V2::GetSchemaService.new(es),
                    Schemas::HashlinkGenerator
                  )
                  filename, data = service.call(namespace: namespace, dri: dri)

                  response.headers['Content-Disposition'] =
                    "attachment; filename=\"#{filename}\""
                  data
                end
              end

              r.get do
                service = Schemas::Services::V2::GetSchemaService.new(es)
                service.call(namespace: namespace, dri: dri)
              end
            end

            r.get do
              service = Schemas::Services::V2::SearchSchemasService.new(es)
              service.call(r.params.merge(namespace: namespace))
            end

            r.post do
              service = Schemas::Services::V2::ImportSchemaService.new(
                es, ::Schemas::HashlinkGenerator
              )
              begin
                dri = service.call(namespace, r.params)

                {
                  success: true,
                  DRI: dri,
                  url: "#{r.base_url}/api/v2/schemas/#{namespace}/#{dri}"
                }
              rescue StandardError => e
                puts e.backtrace
                {
                  success: false,
                  errors: [e.message],
                  url: "#{r.base_url}/api/v2/schemas"
                }
              end
            end
          end

          r.get do
            service = Schemas::Services::V2::SearchSchemasService.new(es)
            service.call(r.params)
          end
        end
      end

      r.on 'v3' do
        r.on 'namespaces' do
          r.on String do |namespace|
            r.on 'schemas' do
              r.get do
                schema_read_repo = ::Schemas::Repositories::SchemaReadRepo.new(es)
                service = Schemas::Services::V3::SearchSchemasService.new(
                  schema_read_repo
                )
                service.call(r.params.merge('namespace' => namespace))
              end

              r.post do
                schema_write_repo = ::Schemas::Repositories::SchemaWriteRepo.new(
                  es, ::Schemas::HashlinkGenerator
                )
                service = ::Schemas::Services::V3::ImportSchemaService.new(
                  ::Schemas::Services::V3::ImportSchemaBaseService.new(
                    schema_write_repo
                  ),
                  ::Schemas::Services::V3::ImportBranchService.new(schema_write_repo)
                )
                begin
                  dri = service.call(namespace, r.params)

                  {
                    success: true,
                    DRI: dri,
                    path: "#{r.base_url}/api/v3/schemas/#{dri}"
                  }
                rescue StandardError => e
                  puts e.backtrace
                  {
                    success: false,
                    errors: [e.message],
                    path: "#{r.base_url}/api/v3/schemas"
                  }
                end
              end
            end
          end

          r.get do
            # TODO
            []
          end
        end

        r.on 'schemas' do
          r.on String do |dri|
            r.on 'archive' do
              r.get do
                schema_read_repo = ::Schemas::Repositories::SchemaReadRepo.new(es)
                service = Schemas::Services::V3::GenerateArchiveService.new(
                  Schemas::Services::V3::GetSchemaService.new(schema_read_repo),
                  Schemas::HashlinkGenerator
                )
                filename, data = service.call(dri)

                response.headers['Content-Disposition'] =
                  "attachment; filename=\"#{filename}\""
                data
              end
            end

            r.get do
              schema_read_repo = ::Schemas::Repositories::SchemaReadRepo.new(es)
              service = Schemas::Services::V3::GetSchemaService.new(
                schema_read_repo
              )
              service.call(dri)
            end
          end

          r.get do
            schema_read_repo = ::Schemas::Repositories::SchemaReadRepo.new(es)
            service = Schemas::Services::V3::SearchSchemasService.new(
              schema_read_repo
            )
            service.call(r.params)
          end
        end
      end
    end
  end
end
