require "test_helper"

# Base test class for all integration tests
class ApplicationIntegrationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers if defined?(Devise)
  
  # Helper to parse JSON responses
  def json_response
    @json_response ||= JSON.parse(response.body, symbolize_names: true)
  end
  
  # Helper to set headers for API requests
  def set_headers(auth_token = nil)
    @request.headers['Accept'] = 'application/json'
    @request.headers['Content-Type'] = 'application/json'
    @request.headers['Authorization'] = "Bearer #{auth_token}" if auth_token
  end
  
  # Helper to test JSON API responses
  def assert_json_response(expected_status = :ok, message = nil)
    assert_response expected_status, message
    assert_equal 'application/json; charset=utf-8', response.content_type, "Expected JSON response"
  end
  
  # Helper to test error responses
  def assert_error_response(status, error_message = nil)
    assert_json_response status
    assert_includes json_response[:error], error_message if error_message
  end
  
  # Helper to test paginated responses
  def assert_paginated_response(collection_key, expected_count = nil)
    assert_json_response
    assert json_response.key?(collection_key), "Response should include #{collection_key} key"
    assert json_response.key?(:meta), "Response should include meta data"
    assert json_response[:meta].key?(:current_page), "Meta should include current_page"
    assert json_response[:meta].key?(:total_pages), "Meta should include total_pages"
    assert json_response[:meta].key?(:total_count), "Meta should include total_count"
    
    if expected_count
      assert_equal expected_count, json_response[collection_key].count, 
                   "Expected #{expected_count} #{collection_key}"
    end
  end
end
