require_relative '03_associatable'

module Associatable

  def has_one_through(name, through_name, source_name)
    through_options = assoc_options[through_name]
    define_method name do
      source_options = through_options.model_class.assoc_options[source_name]
      foreign_key_value = self.send(through_options.foreign_key)
      result = DBConnection.execute(
        "SELECT
          #{source_options.table_name}.*
        FROM
          #{through_options.table_name}
        JOIN
          #{source_options.table_name}
        ON
          #{through_options.table_name}.#{source_options.foreign_key}
          = #{source_options.table_name}.#{source_options.primary_key}
        WHERE
          #{through_options.table_name}.#{through_options.primary_key} = ?
        LIMIT
          1",
        foreign_key_value
      )
      source_options.model_class.parse_all(result)[0]
    end
  end
end
