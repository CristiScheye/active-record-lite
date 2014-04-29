require_relative 'db_connection'
require_relative '02_sql_object'

module Searchable
  def where(params)
    attrs = params.keys.map do |attr|
      "#{attr} = ?"
    end.join(' AND ')

    DBConnection.execute(<<-SQL, params.values)
    SELECT
      *
    FROM
      "#{self.table_name}"
    WHERE
      "#{attrs}"
    SQL
  end
end

class SQLObject
  extend Searchable

  def self.where(params)
    results = super(params)
    parse_all(results)
  end
end
