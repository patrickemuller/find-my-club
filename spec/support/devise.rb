RSpec.configure do |config|
  # Include Devise test helpers for controller and request specs
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::ControllerHelpers, type: :view

  [ :system, :request ].each do |test_type|
    config.include Devise::Test::IntegrationHelpers, type: test_type
  end
  # For system tests, we need to use Warden test helpers
  # and login through the actual UI
  config.include Warden::Test::Helpers, type: :system

  # Clean up Warden after each test
  config.after(type: :system) do
    Warden.test_reset!
  end
end
