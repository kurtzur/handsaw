require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = params.keys.map { |key| "#{key} = ?" }.join(" AND ")
    results = DBConnection.execute(
      "SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{where_line}",
      *params.values
    )
    self.parse_all(results)
  end
end

class SQLObject
  extend Searchable
end
