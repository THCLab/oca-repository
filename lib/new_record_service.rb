class NewRecordService
  attr_reader :es

  def initialize(es)
    @es = es
  end

  def call(filename:, json:)
    es.index(:odca).type(:schema)
      .put(filename, { json: json } )
  end
end
