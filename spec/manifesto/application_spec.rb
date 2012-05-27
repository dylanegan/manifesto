require 'helper'

describe Manifesto::Application do
  include Rack::Test::Methods

  def app
    Manifesto::Application
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
  end
end
