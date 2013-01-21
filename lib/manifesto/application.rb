require 'manifesto'

require 'sinatra/base'
require 'haml'
require 'omniauth/strategies/google_apps'
require 'openid/store/sequel'
require 'rack/csrf'

module Manifesto
  class Application < Sinatra::Base
    $stdout.sync = true

    Manifesto.setup_database(ENV['RACK_ENV'])

    configure :test do
      enable :raise_errors
    end

    set :static, true
    set :root, File.dirname(__FILE__) + '/../../'

    set :haml, :escape_html => true

    use Rack::Session::Cookie, :key => 'rack.session',
      :expire_after => 1209600,
      :secret => ENV['RACK_COOKIE_SECRET'] || raise("missing RACK_COOKIE_SECRET")

    use OmniAuth::Builder do
      provider :google_apps, domain: ENV['GOOGLE_OAUTH_DOMAIN'], store: OpenID::Store::Sequel.new
    end

    use Rack::Csrf, :raise => true, :skip => ['POST:/auth/.*', 'GET:/auth/.*']

    require File.dirname(__FILE__) + '/../../models/api_key'
    require File.dirname(__FILE__) + '/../../models/manifest'
    require File.dirname(__FILE__) + '/../../models/release'

    before do
      unless request.path_info =~ /\/auth/
        authenticate_or_redirect!
      end
    end

    get '/' do
      redirect '/manifests'
    end

    get '/auth/logout' do
      session.clear
      "You're logged out. <a href='/'>Login</a>"
    end

    get('/auth/google_apps/callback') { google_apps_callback }
    post('/auth/google_apps/callback') { google_apps_callback }

    get '/auth/unauthorized' do
      session.clear
      halt 401, haml(:'auth/401', :layout => false)
    end

    get '/manifests' do
      @manifests = Manifest.order(:name)
      haml :'manifests/index'
    end

    get '/manifests/new' do
      @manifest = Manifest.new
      haml :'manifests/new'
    end

    post '/manifests' do
      @manifest = Manifest.new(params[:manifest])

      if @manifest.save(:raise_on_failure => false)
        redirect "/manifests/#{@manifest.name}"
      end

      haml :'manifests/new'
    end

    get '/manifests/:name' do
      if @manifest = Manifest.where(:name => params[:name]).first
        haml :'manifests/show'
      else
        404
      end
    end

    get '/api_keys' do
      @api_keys = APIKey.order(:username, :expires_at)
      haml :'api_keys/index'
    end

    post '/api_keys' do
      @api_key = APIKey.new(params[:api_key])
      if @api_key.save(:raise_on_failure => false)
        @api_keys = APIKey.order(:username, :expires_at)
        haml :'api_keys/index'
      else
        haml :'api_keys/new'
      end
    end

    helpers do
      def csrf_token
        Rack::Csrf.token(env)
      end

      def csrf_tag
        Rack::Csrf.tag(env)
      end
    end

    def authenticate_or_redirect!
      unless current_user
        redirect(to('/auth/unauthorized'))
      end
    end

    def current_user
      @current_user ||= session['user']
    end

    def google_apps_callback
      unless session['user']
        user = env['omniauth.auth']['info']
        email = user['email'].is_a?(Array) ? user['email'].first : user['email']
        email = email.downcase
        session['user'] = {
          'identity_url' => env['omniauth.auth']['uid'],
          'email' => email,
          'first_name' => user['first_name'],
          'last_name' => user['last_name']
        }
      end
      redirect to('/')
    end
  end
end
