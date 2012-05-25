require './app'

use Rack::SslEnforcer if ENV['ENABLE_SSL_ENFORCER']

use Rack::Session::Cookie, :key => 'rack.session',
  :expire_after => 1209600,
  :secret => ENV['RACK_COOKIE_SECRET'] || raise("missing RACK_COOKIE_SECRET")

use OmniAuth::Strategies::GoogleApps,
  OpenID::Store::Sequel.new,
  :name => 'google',
  :domain => ENV['GOOGLE_OAUTH_DOMAIN']

use Rack::Csrf, :raise => true, :skip => ['POST:/auth/.*', 'GET:/auth/.*', 'POST:/manifests/.+/release', 'POST:/manifests/.+/follow', 'POST:/manifests/.+/fork', 'DELETE:/manifests/.+']

class ::Logger; alias_method :write, :<<; end
logger = ENV['RACK_ENV'] == 'test' ? Logger.new('log/test.log') : Logger.new(STDOUT)
use Rack::CommonLogger, logger

run Manifesto::Application
