require_relative '02_searchable'
require 'active_support/inflector'

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    @class_name.underscore + "s"
  end
end

class BelongsToOptions < AssocOptions
  
  def initialize(name, options = {})
    defaults = {
      foreign_key: "#{name}_id".to_sym,
      primary_key: :id,
      class_name: name.to_s.camelize
    }
    
    overridden_defaults = defaults.merge(options)
    
    %w(foreign_key primary_key class_name).each do |ivar_name|
      instance_variable_set "@#{ivar_name}", overridden_defaults[ivar_name.to_sym]
    end
    
  end
end

class HasManyOptions < AssocOptions
  
  def initialize(name, self_class_name, options = {})
    defaults = {
      foreign_key: "#{self_class_name.underscore}_id".to_sym,
      primary_key: :id,
      class_name: name.to_s.singularize.camelize
    }
    
    overridden_defaults = defaults.merge(options)
    
    %w(foreign_key primary_key class_name).each do |ivar_name|
      instance_variable_set "@#{ivar_name}", overridden_defaults[ivar_name.to_sym]
    end
  end
end

module Associatable

  def assoc_options
    @assoc_options ||= {}
  end
  
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options  
      
    define_method name do
      foreign_key_value = self.send(options.foreign_key)
      model_class = options.model_class
      
      result = DBConnection.execute(
        "SELECT
          *
        FROM
          #{options.table_name}
        WHERE
          #{options.primary_key} = ?
        LIMIT
          1",
        foreign_key_value
      )
      model_class.parse_all(result)[0]
    end
  end

  def has_many(name, options = {})
    
    define_method name do
      options = HasManyOptions.new(name, self.class.to_s, options)
      primary_key_value = self.send(options.primary_key)
      model_class = options.model_class
      
      result = DBConnection.execute(
        "SELECT
          *
        FROM
          #{options.table_name}
        WHERE
          #{options.foreign_key} = ?",
        primary_key_value
      )
      model_class.parse_all(result)
    end
  end

end

class SQLObject
  extend Associatable
end
