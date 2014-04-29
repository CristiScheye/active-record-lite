require_relative '04_associatable'


module Associatable
  def has_one_through(name, through_name, source_name)
    through_options = self.assoc_options[through_name]

    define_method(name) do
      source_options = BelongsToOptions.new(source_name)
      source_table = source_options.table_name
      through_table = through_options.table_name
      id_to_find = self.send(through_options.foreign_key)

      results = DBConnection.execute(<<-SQL)
      SELECT #{source_table}.*
      FROM #{source_table}
      JOIN #{through_table}
      ON #{source_table}.#{source_options.primary_key} = #{through_table}.#{source_options.foreign_key}
      WHERE #{through_table}.#{source_options.primary_key} = #{id_to_find}
      SQL

      source_options.model_class.parse_all(results).first
    end
  end
end
