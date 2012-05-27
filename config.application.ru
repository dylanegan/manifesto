$:. << "lib"

require 'manifesto/application'

use Rack::SslEnforcer if ENV['ENABLE_SSL_ENFORCER']

class ::Logger; alias_method :write, :<<; end
logger = ENV['RACK_ENV'] == 'test' ? Logger.new('log/test.log') : Logger.new(STDOUT)
use Rack::CommonLogger, logger

run Manifesto::Application
