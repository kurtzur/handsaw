require_relative 'db_connection'
require 'active_support/inflector'

class SQLObject
  def self.columns
    column_names = DBConnection.execute2("SELECT * FROM #{table_name}")[0]
                   .map(&:to_sym)
    column_names.each do |cname|
      define_method(cname) do
        attributes[cname]
      end
      
      define_method("#{cname}=") do |value|
        attributes[cname] = value
      end
    end
    column_names 
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(
      "SELECT
        #{table_name}.*
      FROM
        #{table_name}"
    )
    parse_all(results)
  end
  
  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  def self.find(id)
    result = DBConnection.execute(
      "SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?",
      id
    )
    parse_all(result)[0]
  end

  def attributes
    @attributes ||= {}
  end

  def insert
    col_names = attributes.keys
    question_marks = (["?"] * col_names.count).join(", ")
    DBConnection.execute(
      "INSERT INTO
        #{self.class.table_name} (#{col_names.join(", ")})
      VALUES
        (#{question_marks})",
      *attribute_values
    )
    self.id = DBConnection.last_insert_row_id
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      unless self.class.columns.include?(attr_name)
        raise "unknown attribute '#{attr_name}'"
      end
      self.send("#{attr_name}=", value)
    end
  end

  def save
    self.id.nil? ? insert : update
  end

  def update
    col_names = attributes.keys.map { |name| "#{name} = ?" }
    DBConnection.execute(
      "UPDATE
        #{self.class.table_name}
      SET
        #{col_names.join(", ")}
      WHERE
        id = ?",
      *attribute_values,
      self.id
    )
  end

  def attribute_values
    attributes.values
  end
end
