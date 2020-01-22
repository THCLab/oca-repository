# ODCA Search Engine

### API
`GET /schemas` returns first 20 schemas  
`GET /schemas?q={query}` returns schemas which matches query  
`GET /schemas/{hashlink}` returns schema json for given hashlink  
`POST /schema/new` store schema given in `schema` param, returns hashlink
