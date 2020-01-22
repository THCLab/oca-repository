# ODCA Search Engine

### API
`GET /schemas` returns first 20 schemas  
`GET /schemas?q={query}` returns schemas which any field matches query  
`GET /schemas?{field1}={query1}&{field2}={query2}&...` returns schemas which given fields matches queries  
`GET /schemas/{hashlink}` returns schema json for given hashlink  
`POST /schema/new` store schema given in `schema` param, returns hashlink
