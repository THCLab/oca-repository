# OCA Repository

## API

### v3

#### namespaces

`GET /v3/namespaces/{namespace}/schemas`  
___search for schemas in specified namespace (optional params as listed above)___

`POST /v3/namespaces/{namespace}/schemas`  
___store schema given in form file, returns DRI and url___

- Add schema base by uploading its JSON file  
- Add schema branch by uploading ZIP file with given structure:
   ```bash
   file.zip
   ├── schemaName
   │    ├── overlay1.json
   │    └── overlay2.json
   └── schemaName.json (schema base)
   ```

#### schemas

`GET /v3/schemas`  
___returns list of schemas___  

   ```
   optional params:  
      ?suggest={suggestion} - returns list of all schemas which namespace or name starts with given string (when provided rest of params are ignored)  
      ?namespace={namespace} - returns filtered schemas by namespace  
      ?q={query} - returns schemas which any field matches query  
      ?type={type} - returns schemas which matches selected type (ex. 'schema_base' / 'overlay' / 'label' / 'entry' / ...)
      ?limit={number} - set max number of results to be returned (default 1000)  
   ```

`GET /v3/schemas/{DRI}`  
___returns schema json for given DRI___

`GET /v3/schemas/{DRI}/archive`  
___triggers downloading schema archive for given DRI___

### v2
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

### v1
`GET /schemas` returns first 20 schemas  
`GET /schemas?q={query}` returns schemas which any field matches query  
`GET /schemas?{field1}={query1}&{field2}={query2}&...` returns schemas which given fields matches queries  
`GET /schemas/{hashlink}` returns schema json for given hashlink  
`POST /schemas` store schema given in request body, returns hashlink


## Development

1. Build docker image  
`docker build . -t odca-search-engine`  
1. Create external docker network  
`docker network create odca`  
1. Run  
`docker-compose up`  
It serves:
   1. OCA Repository app on port `9292`
   1. ElasticSearch on port `9200`
   1. Swagger on port `8000`
