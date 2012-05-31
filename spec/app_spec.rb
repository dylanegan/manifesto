require 'helper'

describe Manifesto::Application do
  include Rack::Test::Methods

  def app
    @app ||= Rack::Builder.new do
      use Rack::Session::Cookie, :key => 'rack.session'
      use OmniAuth::Builder do
        provider :google_apps, domain: ENV['GOOGLE_OAUTH_DOMAIN'], store: OpenID::Store::Sequel.new
      end
      run Manifesto::Application
    end
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
        last_response.body.must_include('Logged in.')
      end

      it "should log out the user" do
        mock_google_apps_auth
        get "/auth/google_apps"
        get "/auth/logout"
        last_request.env['rack.session']['user'].must_be_nil
      end
    end
  end


  describe "cutting a new manifest release" do
    before do
      @api_key = APIKey.new(:username => 'shawesome')
      @api_key.save

      header 'Accept', 'application/json'
      basic_authorize 'shawesome', @api_key.key
      @manifest = create_manifest
      @release = create_release(:manifest_id => @manifest.id)

      post "/manifests/#{@manifest.name}/release", { 'other_component' => '1' }.to_json, :content_type => :json
    end

    it "should cut a new Release for the Manifest" do
      @manifest.releases.count.must_equal 2
    end

    it "should merge the release components" do
      @manifest.current.components.must_equal({ 'component' => '1', 'other_component' => '1' })
    end

    it "returns the release" do
      last_response.body.must_equal @manifest.current.to_json
    end

    it "should return created" do
      last_response.status.must_equal 201
    end
  end

  describe "cutting a new release manifest by removing a component" do
    before do
      @api_key = APIKey.new(:username => 'shawesome')
      @api_key.save

      header 'Accept', 'application/json'
      basic_authorize 'shawesome', @api_key.key
      @manifest = create_manifest
      @release = create_release(:manifest_id => @manifest.id, :components => { 'old_component' => 1, 'component' => 2 })

      post "/manifests/#{@manifest.name}/release", { 'old_component' => nil }.to_json, :content_type => :json
    end

    it "should cut a new Release for the Manifest" do
      @manifest.releases.count.should == 2
    end

    it "should not include the removed component in the release" do
      @manifest.current.components.should == { 'component' => 2 }
    end

    it "returns the release" do
      last_response.body.should == @manifest.current.to_json
    end

    it "should return created" do
      last_response.status.should == 201
    end
  end

  describe "GET manifest.json" do
    before do
      @api_key = APIKey.new(:username => 'shawesome')
      @api_key.save

      header 'Accept', 'application/json'
      basic_authorize 'shawesome', @api_key.key
      @manifest = create_manifest
    end

    describe "on existing manifest" do
      it "should cut a new Release for the Manifest" do
        get "/manifests/#{@manifest.name}.json"
        last_response.status.must_equal 200
      end
    end

    describe "on non-existing manifest" do
      it "should return created" do
        get "/manifests/non-existant.json"
        last_response.status.must_equal 404
      end
    end
  end

  describe "forking a manifest" do
    before do
      @api_key = APIKey.new(:username => 'shawesome')
      @api_key.save

      header 'Accept', 'application/json'
      basic_authorize 'shawesome', @api_key.key
      @manifest = create_manifest
      @release = create_release(:manifest_id => @manifest.id)

      post "/manifests/#{@manifest.name}/fork", { 'name' => 'fork' }.to_json, :content_type => :json
      @forked = Manifest.where(:name => 'fork').first
    end

    it "should cut a new Release for the Manifest" do
      @forked.releases.last.components.must_equal @manifest.releases.last.components
    end

    it "should return created" do
      last_response.status.must_equal 201
    end
  end

  describe "following a manifest" do
    before do
      @api_key = APIKey.new(:username => 'shawesome')
      @api_key.save

      header 'Accept', 'application/json'
      basic_authorize 'shawesome', @api_key.key
      @manifest = create_manifest

      post "/manifests/#{@manifest.name}/follow", { 'name' => 'follower', 'follower_override' => { 'other' => 'amazing' } }.to_json, :content_type => :json
      @follower = Manifest.where(:name => 'follower').first
    end

    it "should create a follower" do
      @follower.followee.must_equal @manifest

      post "/manifests/#{@manifest.name}/release", { 'other' => 'something', 'noir' => 'awesome' }.to_json, :content_type => :json

      @follower.reload
      @follower.releases.first.components.must_equal({ 'other' => 'amazing', 'noir' => 'awesome' })
    end

    it "should return created" do
      last_response.status.must_equal 201
    end

    describe "with an updated manifest" do
      before do
        put "/manifests/#{@follower.name}", { 'follower_override' => { 'other' => 'shamazing' } }.to_json, :content_type => :json
        post "/manifests/#{@follower.name}/release", { 'other' => 'something', 'noir' => 'awesome' }.to_json, :content_type => :json

        @follower.reload
      end

      it "should use the updated override" do
        @follower.current.components.must_equal({ 'other' => 'shamazing', 'noir' => 'awesome' })
      end

      it "should return created" do
        last_response.status.must_equal 201
      end
    end
  end

  describe "destroying a manifest" do
    before do
      @api_key = APIKey.new(:username => 'shawesome')
      @api_key.save

      header 'Accept', 'application/json'
      basic_authorize 'shawesome', @api_key.key
      @manifest = create_manifest

      delete "/manifests/#{@manifest.name}", :content_type => :json
    end

    it "should destroy the manifest" do
      Manifest[@manifest.id].must_be_nil
    end
  end
end
