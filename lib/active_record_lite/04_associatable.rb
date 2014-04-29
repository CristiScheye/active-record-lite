require_relative '03_searchable'
require 'active_support/inflector'
require 'debugger'

# Phase IVa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.to_s.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @name = name.to_sym
    @foreign_key = options[:foreign_key] || "#{name}_id".to_sym
    @primary_key = options[:primary_key] || :id
    @class_name  = options[:class_name]  || name.to_s.capitalize
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @name = name.to_sym
    @foreign_key = options[:foreign_key] || "#{self_class_name}_id".downcase.to_sym
    @primary_key = options[:primary_key] || :id
    @class_name  = options[:class_name]  || name.to_s.camelcase.singularize
  end
end

module Associatable
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name.to_sym] = options

    define_method(name) do
      primary_id_to_find = self.send(options.foreign_key)
      results = DBConnection.execute(<<-SQL, primary_id_to_find)
      SELECT
        *
      FROM
        "#{options.table_name}"
      WHERE
        "#{options.primary_key}" = ?
      SQL

      options.model_class.parse_all(results).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self, options)

    define_method(name) do
      my_primary_key = self.send(options.primary_key)
      results = DBConnection.execute(<<-SQL, my_primary_key)
      SELECT
        *
      FROM
        "#{options.table_name}"
      WHERE
        "#{options.foreign_key}" = ?
      SQL
      options.model_class.parse_all(results)
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
