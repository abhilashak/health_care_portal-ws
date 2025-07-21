require "test_helper"

# Base test class for all controller tests
class ApplicationControllerTestCase < ActionDispatch::IntegrationTest
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
  
  # Helper to assert response status and content type
  def assert_response_format(status = :ok, content_type: 'application/json')
    assert_response status
    assert_equal content_type, response.content_type
  end
  
  # Helper to test strong parameters
  def assert_permitted_params(controller_class, permitted_params, params_key = nil)
    params_key ||= controller_class.controller_name.singularize
    assert_equal permitted_params.sort, controller_class.new.send(:resource_params).keys.map(&:to_s).sort,
                 "Expected #{controller_class} to permit params: #{permitted_params}"
  end
  
  # Helper to test authentication requirements
  def assert_requires_authentication(method, path, **options)
    process method, path: path, params: options[:params], xhr: options[:xhr]
    assert_redirected_to new_user_session_path
    assert_equal 'You need to sign in or sign up before continuing.', flash[:alert]
  end
  
  # Helper to test authorization requirements
  def assert_requires_authorization(user, method, path, **options)
    sign_in(user) if user
    process method, path: path, params: options[:params], xhr: options[:xhr]
    assert_redirected_to root_path
    assert_equal 'You are not authorized to perform this action.', flash[:alert]
  end
end
