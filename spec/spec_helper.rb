# spec/spec_helper.rb
require 'rspec'
require 'rack/test'
require 'json'

# Set test environment before requiring the app
ENV['RACK_ENV'] = 'test'

# Add the project root to the load path
$LOAD_PATH.unshift File.expand_path('..', __dir__)

# Require the application
require_relative '../app'

RSpec.configure do |config|
  # Use Rack::Test for testing Sinatra apps
  config.include Rack::Test::Methods

  # Define the app method for Rack::Test
  def app
    Sinatra::Application
  end

  # Configure test database cleanup
  config.before(:each) do
    # Only clean up if database is available
    begin
      PostgresClient.connect[:urls].delete
      RedisClient.reset_counter
    rescue => e
      puts "Warning: Could not connect to database for cleanup: #{e.message}"
    end
  end

  # Filter out slow tests by default
  config.filter_run_excluding slow: true

  # Run tests in random order
  config.order = :random

  # Enable should syntax
  config.expect_with :rspec do |expectations|
    expectations.syntax = [:should, :expect]
  end

  # Enable mock syntax
  config.mock_with :rspec do |mocks|
    mocks.syntax = [:should, :expect]
  end
end
