class NewRecordService
  attr_reader :es

  def initialize(es)
    @es = es
  end

  def call(hashlink:, schema:)
    es.index(:odca).type(:schema)
      .put(hashlink, { json: schema } )
  end
end
