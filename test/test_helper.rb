require "simplecov"
SimpleCov.start "rails" do
  add_filter "/test/"
  add_filter "/config/"
  add_filter "/vendor/"
  add_filter "/db/"
  enable_coverage :branch
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

require "shoulda/context"
require "shoulda/matchers"
require "mocha/minitest"

module SignInHelper
  def sign_in(user)
    post session_url, params: { email_address: user.email_address, password: "password123" }
  end
end

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    # SimpleCov: merge results from parallel workers
    parallelize_setup do |worker|
      SimpleCov.command_name "#{SimpleCov.command_name}-#{worker}"
    end

    parallelize_teardown do |worker|
      SimpleCov.result
    end

    # Use factories instead of fixtures
    include FactoryBot::Syntax::Methods
  end
end

class ActionDispatch::IntegrationTest
  include SignInHelper
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :rails
  end
end
