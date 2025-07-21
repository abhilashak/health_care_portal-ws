# frozen_string_literal: true

# Base helper for system tests
module ApplicationSystemTestHelper
  # Helper to fill in rich text areas
  def fill_in_rich_text_area(locator = nil, with:)
    find(:rich_text_area, locator).execute_script("this.editor.loadHTML(arguments[0])", with.to_s)
  end
  
  # Helper to check if an element is visible
  def visible?(selector, **options)
    find(selector, **options).present?
  rescue Capybara::ElementNotFound
    false
  end
  
  # Helper to wait for an element to appear
  def wait_for_selector(selector, **options)
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until page.has_selector?(selector, **options)
      find(selector, **options)
    end
  end
  
  # Helper to wait for an element to be removed
  def wait_for_removal(selector, **options)
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop while page.has_selector?(selector, **options)
    end
  end
  
  # Helper to accept browser alerts
  def accept_confirm(message = nil, **options, &block)
    page.driver.browser.switch_to.alert.accept
  rescue Selenium::WebDriver::Error::NoSuchAlertError
    # Alert already handled
  end
  
  # Helper to dismiss browser alerts
  def dismiss_confirm(message = nil, **options, &block)
    page.driver.browser.switch_to.alert.dismiss
  rescue Selenium::WebDriver::Error::NoSuchAlertError
    # Alert already handled
  end
  
  # Helper to test file uploads
  def attach_file_to(field_name, file_path)
    find("##{field_name}", visible: :all).attach_file(file_path)
  end
  
  # Helper to test date pickers
  def select_date(date, options = {})
    field = options[:from]
    select date.year.to_s,  from: "#{field}_1i"
    select date.strftime('%B'), from: "#{field}_2i"
    select date.day.to_s,   from: "#{field}_3i"
  end
  
  # Helper to test time pickers
  def select_time(time, options = {})
    field = options[:from]
    select time.strftime('%H'), from: "#{field}_4i"
    select time.strftime('%M'), from: "#{field}_5i"
  end
end

# Include the helper in ApplicationSystemTestCase
ApplicationSystemTestCase.include ApplicationSystemTestHelper
