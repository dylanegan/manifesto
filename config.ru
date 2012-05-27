require File.dirname(__FILE__) + '/lib/manifesto/api/v1'
require File.dirname(__FILE__) + '/lib/manifesto/application'

use Rack::SslEnforcer if ENV['ENABLE_SSL_ENFORCER']

class ::Logger; alias_method :write, :<<; end
logger = ENV['RACK_ENV'] == 'test' ? Logger.new('log/test.log') : Logger.new(STDOUT)
use Rack::CommonLogger, logger

run Rack::Cascade.new [Manifesto::API::V1, Manifesto::Application]
