ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

# Configure WebMock to allow local requests but block external ones
WebMock.disable_net_connect!(allow_localhost: true)

# Ensure Devise mappings are loaded
Rails.application.reload_routes!

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    # parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Include FactoryBot methods (build, create, etc.)
    include FactoryBot::Syntax::Methods

    # Add more helper methods to be used by all tests here...
  end
end

# Include Devise test helpers for integration tests
class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
