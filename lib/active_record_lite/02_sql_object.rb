require_relative 'db_connection'
require_relative '00_attr_accessor_object'
require 'active_support/inflector'
require 'debugger'
class MassObject
  def self.parse_all(results)
    results.map do |r| #r is a hash "id" => "2"
      self.new(r)
    end
  end
end

class SQLObject < MassObject
  def self.columns
    if !!@cols #only run this once
      @cols
    else
      rows = DBConnection.execute2("SELECT * FROM #{table_name} LIMIT 1")
      @cols = rows.first.map(&:to_sym)

      @cols.each do |col|
        define_method(col) { attributes[col] }
        define_method("#{col}=".to_sym) { |val| attributes[col] = val }
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.to_s.underscore.pluralize
  end

  def self.all
    results = DBConnection.execute("SELECT * FROM #{table_name}")
    parse_all(results)
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
    SELECT
      "#{table_name}".*
    FROM
      "#{table_name}"
    WHERE
      "#{table_name}".id = ?
    LIMIT
      1
    SQL
    parse_all(results).first
  end

  def attributes
    @attributes ||= Hash.new
  end

  def insert
    col_names = self.class.columns - [:id]
    q_marks = Array.new(col_names.size, '?')

    DBConnection.execute(<<-SQL, self.attribute_values)
    INSERT INTO
      "#{self.class.table_name}" ("#{col_names.join(', ')}")
    VALUES
      ("#{q_marks.join(', ')}")
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def initialize(attrs = {})
    attrs.each do |attr_name, attr_val|
      if self.class.columns.include?(attr_name.to_sym)
        self.send("#{attr_name}=", attr_val)
      else
        raise "unknown attribute #{attr_name}"
      end
    end
  end

  def save
    id.nil? ? insert : update
  end

  def update
    sql_set = attributes.keys.map do |attr_name|
      "#{attr_name} = ?"
    end.join(', ')

    DBConnection.execute(<<-SQL, attributes.values, self.id)
    UPDATE
      "#{self.class.table_name}"
    SET
      "#{sql_set}"
    WHERE
      id = ?
    SQL
  end

  def attribute_values
    attributes.values
  end
end
