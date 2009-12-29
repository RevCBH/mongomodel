module MongoModel
  module Validations
    extend ActiveSupport::Concern
    
    include ActiveModel::Validations
    
    module ClassMethods
      def property(name, *args, &block) #:nodoc:
        property = super
        
        validates_associated(name) if property.embeddable?
        validates_presence_of(name) if property.options[:required]
        validates_format_of(name, property.options[:format]) if property.options[:format]
        
        property
      end
      
      # Set the i18n scope to overwrite ActiveModel.
      def i18n_scope #:nodoc:
        :mongomodel
      end
    end
    
    def valid?
      errors.clear
      
      @_on_validate = new_record? ? :create : :update
      run_callbacks(:validate)
      
      errors.empty?
    end
  end
end

Dir[File.dirname(__FILE__) + "/validations/*.rb"].sort.each do |path|
  filename = File.basename(path)
  require "mongomodel/concerns/validations/#{filename}"
end
