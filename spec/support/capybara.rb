require "capybara/rspec"
require "capybara/cuprite"

Capybara.server = :puma, { Silent: true }
Capybara.default_max_wait_time = 5

Capybara.register_driver :cuprite do |app|
  Capybara::Cuprite::Driver.new(
    app,
    browser_options: { "no-sandbox": nil },
    process_timeout: 15,
    window_size: [ 1400, 1000 ]
  )
end

Capybara.default_driver = :rack_test
Capybara.javascript_driver = :cuprite

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by Capybara.javascript_driver
  end
end
