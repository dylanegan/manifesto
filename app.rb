# /usr/bin/env ruby
$: << "./lib"

require 'securerandom'
require 'sinatra/base'
require 'json'

require 'manifesto'
require 'haml'
require 'omniauth/strategies/google_apps'
require 'openid/store/sequel'
require 'rack/request'
require 'rack/csrf'
require 'rack-flash'
require 'sequel'

module Manifesto
  class Application < Sinatra::Base
    $stdout.sync = true

    configure :development, :production do
      DB = Sequel.connect(ENV['DATABASE_URL'] || 'postgres://localhost/manifesto_development')
    end

    configure :test do
      DB = Sequel.connect("sqlite::memory:")
      Sequel.extension :migration
      Sequel::Migrator.run(DB, File.expand_path(File.dirname(__FILE__) + "/migrations"))

      enable :raise_errors
    end

    # Load models
    require './models/api_key'
    require './models/manifest'
    require './models/release'

    use Rack::Flash
    set :static, true
    set :root, File.dirname(__FILE__)

    set :haml, :escape_html => true

    before do
      unless request.path_info =~ /\/auth/
        authenticate_or_redirect!
      end
    end

    get '/' do
      redirect '/manifests'
    end

    # Auth
    get '/auth/logout' do
      session.clear
      "You're logged out. <a href='/'>Login</a>"
    end

    post '/auth/google_apps/callback' do
      unless session['user']
        user = env['omniauth.auth']['user_info']
        email = user['email'].is_a?(Array) ? user['email'].first : user['email']
        email = email.downcase
        session['user'] = {
          'identity_url' => env['omniauth.auth']['uid'],
          'email' => email,
          'first_name' => user['first_name'],
          'last_name' => user['last_name']
        }
        flash[:notice] = "Logged in."
      end
      redirect to('/')
    end

    get('/auth/google_apps/callback') { google_apps_callback }
    post('/auth/google_apps/callback') { google_apps_callback }

    get '/auth/unauthorized' do
      session.clear
      halt 401, haml(:'auth/401', :layout => false)
    end

    # Manifests
    get '/manifests.?:format?' do
      @manifests = Manifest.order(:name)
      if params[:format] == "json"
        content_type :json
        @manifests.to_json
      else
        haml :'manifests/index'
      end
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

    get '/manifests/:name.json' do
      if @manifest = Manifest.where(:name => params[:name]).first
        @manifest.to_json
      else
        404
      end
    end

    get '/manifests/:name' do
      if @manifest = Manifest.where(:name => params[:name]).first
        haml :'manifests/show'
      else
        404
      end
    end

    put '/manifests/:name' do
      content_type :json

      @manifest = Manifest.where(:name => params[:name]).first
      manifest = JSON.parse(request.body.read.to_s)
      if @manifest.update(manifest)
        201
      else
        500
      end
    end

    delete '/manifests/:name' do
      content_type :json

      @manifest = Manifest.where(:name => params[:name]).first
      if @manifest.destroy
        200
      else
        500
      end
    end

    get '/manifests/:name/current' do
      content_type :json
      @manifest = Manifest.where(:name => params[:name]).first
      @manifest.current.components.to_json
    end

    get '/manifests/:name/releases.?:format?' do
      content_type :json
      @manifest = Manifest.where(:name => params[:name]).first
      @manifest.releases.to_json
    end

    post '/manifests/:name/release' do
      content_type :json

      @manifest = Manifest.where(:name => params[:name]).first
      if @release = @manifest.release(JSON.parse(request.body.read.to_s))
        status(201)
        @release.to_json
      else
        403
      end
    end

    post '/manifests/:name/fork' do
      content_type :json

      @manifest = Manifest.where(:name => params[:name]).first
      if @fork = @manifest.fork(JSON.parse(request.body.read.to_s))
        status(201)
        @fork.to_json
      else
        500
      end
    end

    post '/manifests/:name/follow' do
      content_type :json

      follower = JSON.parse(request.body.read.to_s)

      @manifest = Manifest.where(:name => params[:name]).first
      if @manifest.add_follower(follower)
        201
      else
        500
      end
    end

    # API keys
    get '/api_keys' do
      @api_keys = APIKey.order(:username, :expires_at)
      @api_key = APIKey.new
      haml :'api_keys/index'
    end

    post '/api_keys' do
      @api_key = APIKey.new(params[:api_key])
      if @api_key.save(:raise_on_failure => false)
        flash[:success] = "API Key Created|#{@api_key.key}|#{@api_key.expires_at}"
        redirect '/api_keys'
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
        if request.env['HTTP_ACCEPT'] =~ /application\/json/i
          auth = Rack::Auth::Basic::Request.new(request.env)
          if (api_key = APIKey.first(:username => auth.credentials[0], :key => auth.credentials[1]))
            @current_user = api_key
          else
            halt 401
          end
        else
          redirect(to('/auth/unauthorized'))
        end
      end
    end

    def current_user
      @current_user ||= session['user']
    end

    def google_apps_callback
      unless session['user']
        user = env['omniauth.auth']['user_info']
        email = user['email'].is_a?(Array) ? user['email'].first : user['email']
        email = email.downcase
        session['user'] = {
          'identity_url' => env['omniauth.auth']['uid'],
          'email' => email,
          'first_name' => user['first_name'],
          'last_name' => user['last_name']
        }
        flash[:notice] = "Logged in."
      end
      redirect to('/')
    end
  end
end
