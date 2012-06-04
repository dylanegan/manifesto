require "simplecov" unless ENV['NO_SIMPLECOV']
require 'minitest/autorun'

ENV['AWS_ACCESS_KEY_ID'] ||= '1234567890'
ENV['AWS_SECRET_ACCESS_KEY'] ||= 'abcdefghijklmnopqrstuvwxyz'
ENV['GOOGLE_OAUTH_DOMAIN'] = 'example.com'
ENV["RACK_ENV"] = 'test'

require File.join(File.dirname(__FILE__), '..','app.rb')

require 'sinatra'
require 'rack/test'

set :environment, :test

Manifesto.logger = File.open(File.dirname(__FILE__) + '/../log/test.log', 'w')

Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each {|f| require f}

Fog.mock! unless ENV['FOG_REAL']
OmniAuth.config.test_mode = true

# Database cleaner.
require 'database_cleaner'
DatabaseCleaner.strategy = :transaction
class MiniTest::Spec
  before :each do
    DatabaseCleaner.start
  end

  after :each do
    DatabaseCleaner.clean
  end
end
