require 'active_support/core_ext/hash/reverse_merge'
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/string/inflections'

module MongoModel
  class Document < EmbeddedDocument
    extend Finders
    include Scopes
    
    property :id, String, :as => '_id', :default => lambda { ::Mongo::ObjectID.new }
    
    def initialize(attrs={})
      @_new_record = true
      self.attributes = attrs
    end
    
    def new_record?
      @_new_record
    end
    
    def save
      save_to_collection
    end
    
    def delete
      self.class.delete(id)
      freeze
    end
    
    def self.delete(id_or_conditions)
      collection.remove(MongoOptions.new(self, :conditions => id_to_conditions(id_or_conditions)).selector)
    end
    
    def destroy
      delete
    end
    
    def self.destroy(id_or_conditions)
      find(:all, :conditions => id_to_conditions(id_or_conditions)).each { |instance| instance.destroy }
    end
    
    def freeze
      attributes.freeze; self
    end
    
    def frozen?
      attributes.frozen?
    end
    
    def self.from_mongo(document)
      instance = new
      instance.attributes.from_mongo!(document)
      instance.instance_variable_set('@_new_record', false)
      instance
    end
    
    class_inheritable_writer :collection_name
    
    def self.collection_name
      read_inheritable_attribute(:collection_name) || name.tableize.gsub(/\//, '.')
    end
    
    def self.collection
      @_collection ||= database.collection(collection_name)
    end
    
    def collection
      self.class.collection
    end
    
    def self.database
      MongoModel.database
    end
    
    def database
      self.class.database
    end
  
  private
    def save_to_collection
      collection.save(to_mongo)
      @_new_record = false
      true
    end
    
    def self.id_to_conditions(id_or_conditions)
      case id_or_conditions
      when String
        { :id => id_or_conditions }
      when Array
        { :id.in => id_or_conditions }
      else
        id_or_conditions
      end
    end
  end
end
