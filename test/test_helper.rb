ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"
require "minitest/reporters"

# Set up minitest reporters for better test output
Minitest::Reporters.use! [
  Minitest::Reporters::SpecReporter.new,
  Minitest::Reporters::JUnitReporter.new('test/reports')
]

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    
    # Helper method to assert that a record is valid
    def assert_valid(record, message = nil)
      message ||= "Expected #{record.class} to be valid but had errors: #{record.errors.full_messages.to_sentence}"
      assert record.valid?, message
    end
    
    # Helper method to assert that a record is invalid
    def assert_invalid(record, message = nil)
      message ||= "Expected #{record.class} to be invalid but was valid"
      assert_not record.valid?, message
    end
    
    # Helper method to assert that an attribute has errors
    def assert_errors_on(record, attribute, message = nil)
      message ||= "Expected errors on #{attribute} but none found"
      assert record.errors[attribute].present?, message
    end
  end
end

# Configure shoulda matchers if available
begin
  require 'shoulda/matchers'
  Shoulda::Matchers.configure do |config|
    config.integrate do |with|
      with.test_framework :minitest
      with.library :rails
    end
  end
rescue LoadError
  # Shoulda matchers not available
end
