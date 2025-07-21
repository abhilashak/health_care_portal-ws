require "test_helper"

# Base test class for all model tests
class ApplicationModelTestCase < ActiveSupport::TestCase
  # Add model-specific test helpers here
  
  # Helper to test model validations
  def assert_validates_presence_of(model_class, attribute, options = {})
    model = model_class.new
    model.send("#{attribute}=", nil)
    assert_not model.valid?, "#{model_class} should require #{attribute}"
    assert_includes model.errors[attribute], "#{options[:message] || "can't be blank"}"
  end
  
  # Helper to test enum definitions
  def assert_enum(model_class, enum_name, expected_values)
    assert_equal expected_values, model_class.send(enum_name.to_s.pluralize).keys.map(&:to_s), 
                 "Expected #{model_class}.#{enum_name} to have values: #{expected_values}"
  end
  
  # Helper to test associations
  def assert_belongs_to(model_class, association_name, options = {})
    association = model_class.reflect_on_association(association_name)
    assert association, "Expected #{model_class} to have a #{association_name} association"
    assert_equal :belongs_to, association.macro, "Expected #{model_class} to belong to #{association_name}"
    
    if options[:class_name]
      assert_equal options[:class_name], association.class_name, "Expected #{model_class}.#{association_name} to use class #{options[:class_name]}"
    end
  end
  
  def assert_has_many(model_class, association_name, options = {})
    association = model_class.reflect_on_association(association_name)
    assert association, "Expected #{model_class} to have a #{association_name} association"
    assert_equal :has_many, association.macro, "Expected #{model_class} to have many #{association_name}"
    
    if options[:class_name]
      assert_equal options[:class_name], association.class_name, "Expected #{model_class}.#{association_name} to use class #{options[:class_name]}"
    end
  end
end
