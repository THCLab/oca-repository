# ODCA Search Engine

### API
`GET /schemas` returns first 20 schemas  
`GET /schemas?q={query}` returns schemas which any field matches query  
`GET /schemas?{field1}={query1}&{field2}={query2}&...` returns schemas which given fields matches queries  
`GET /schemas/{hashlink}` returns schema json for given hashlink  
`POST /schemas` store schema given in request body, returns hashlink

##### v2
`GET /v2/schemas` search for schemas  
   ```
   optional params:  
      ?limit={number} - set max number of results to be returned (default 1000)  
      ?q={query} - returns schemas which any field matches query  
      ?{field1}={query1}&{field2}={query2}&... - returns schemas which given fields matches queries  
   ```
`GET /v2/schemas/{namespace}` search for schemas in specified namespace (optional params as listed above)  
`GET /v2/schemas/{namespace}/{DRI}` returns schema json for given DRI in specified namespace  
`POST /v2/schemas/{namespace}` store per namespace schema given in form file, returns DRI and url
- Add schema base by uploading its JSON file
- Add schema branch by uploading ZIP file with given structure:
   ```bash
   file.zip
   ├── schemaName
   │    ├── overlay1.json
   │    └── overlay2.json
   └── schemaName.json (schema base)
   ```

### Development

1. Build docker image  
`docker build . -t odca-search-engine`  
1. Create external docker network  
`docker network create odca`  
1. Run  
`docker-compose up`  
It serves:
   1. ODCA Search Engine app on port `9292`
   1. ElasticSearch on port `9200`
   1. Swagger on port `8000`
