require "test_helper"

# Configure Capybara for system tests
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, 
    using: :headless_chrome,
    screen_size: [1400, 1400],
    options: {
      browser: :chrome,
      desired_capabilities: Selenium::WebDriver::Remote::Capabilities.chrome(
        chrome_options: {
          args: %w[headless disable-gpu no-sandbox disable-dev-shm-usage]
        }
      )
    }

  # Helper method to sign in users (to be implemented when authentication is added)
  def sign_in(user)
    # Will be implemented when we have authentication
  end

  # Helper method to wait for JavaScript to finish executing
  def wait_for_js
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until page.evaluate_script('document.readyState') == 'complete'
    end
  end

  # Helper method to wait for AJAX requests to complete
  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until finished_all_ajax_requests?
    end
  end

  def finished_all_ajax_requests?
    page.evaluate_script('jQuery.active').zero?
  rescue
    true # When there's no jQuery
  end

  # Take a screenshot on test failure
  def take_failed_screenshot
    return unless ENV['CI'].blank? # Skip in CI
    
    timestamp = Time.current.strftime("%Y%m%d%H%M%S")
    filename = "screenshot-failure-#{timestamp}.png"
    path = Rails.root.join("tmp/screenshots/#{filename}")
    
    # Create screenshots directory if it doesn't exist
    FileUtils.mkdir_p(File.dirname(path))
    
    # Take the screenshot
    save_screenshot(path)
    puts "Screenshot saved to: #{path}"
  end

  # Take a screenshot after each test if it failed
  teardown do
    if failed? && respond_to?(:page) && page.driver.respond_to?(:save_screenshot)
      take_failed_screenshot
    end
  end
end
