require 'helper'

describe Manifesto::Application do
  include Rack::Test::Methods

  def app
    app_from_config('config.application.ru')
  end

  describe "authentication" do
    describe "via OpenID" do
      before do
        mock_google_apps_auth
      end

      it "should redirect a user if they aren't logged in" do
        OmniAuth.config.mock_auth[:google_apps] = :unauthorized
        get "/"
        follow_redirect!
        last_request.url.must_equal 'http://example.org/auth/unauthorized'
        last_response.status.must_equal 401
      end

      it "should log in a user" do
        get "/auth/google_apps"
        follow_redirect!
        follow_redirect!
        follow_redirect!
        last_response.body.must_include('New Manifest')
      end

      it "should log out the user" do
        mock_google_apps_auth
        get "/auth/google_apps"
        get "/auth/logout"
        last_request.env['rack.session']['user'].must_be_nil
      end
    end

    describe "enforce ssl" do

      after do
        ENV.delete('ENABLE_SSL_ENFORCER')
      end

      it "should use Rack::SslEnforcer when it is enabled" do
        ENV['ENABLE_SSL_ENFORCER'] = "true"
        middleware_classes(app).must_include(Rack::SslEnforcer)
      end

      it "should not use Rack::SslEnforcer when it is not enabled" do
        middleware_classes(app).wont_include(Rack::SslEnforcer)
      end

    end
  end
end
