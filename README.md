# OCA Repository

DEPRECATED: check https://github.com/THCLab/oca-repository-rs

## API

check [swagger](https://repository.oca.argo.colossi.network) for reference


## Development

1. Build docker image
`docker build . -t oca-search-engine`
1. Create external docker network
`docker network create oca`
1. Run
`docker-compose up`
It serves:
   1. OCA Repository app on port `9292`
   1. ElasticSearch on port `9200`
   1. Swagger on port `8000`
