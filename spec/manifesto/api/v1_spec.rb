require 'helper'

describe Manifesto::API::V1 do
  include Rack::Test::Methods

  def app
    Manifesto::API::V1
  end

  before do
    header 'Accept', 'application/vnd.manifesto-v1+json'

    @api_key = APIKey.new(:username => 'shawesome')
    @api_key.save
    basic_authorize 'shawesome', @api_key.key
  end

  describe "authentication" do
    it "should authenticate with legitimate credentials" do
      get '/manifests/manifest'
      last_response.status.wont_equal 401
    end

    it "shouldn't authenticate with illegitimate credentials" do
      basic_authorize 'fail', 'fail'
      get '/manifests/manifest'
      last_response.status.must_equal 401
    end
  end

  describe "cutting a new manifest release" do
    before do
      @manifest = create_manifest
      @release = create_release(:manifest_id => @manifest.id)

      post "/manifests/#{@manifest.name}/release", { 'other_component' => '1' }.to_json
    end

    it "should cut a new Release for the Manifest" do
      @manifest.releases.count.must_equal 3
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

    describe "with scope" do
      it "should merge the release components" do
        post "/manifests/#{@manifest.name}/release", { 'scope' => 'scope', 'other_component' => '1' }.to_json
        @manifest.current.components.must_equal({ 'component' => '1', 'other_component' => '1', 'scope' => { 'other_component' => '1' } })
      end
    end
  end

  describe "GET manifest.json" do
    before do
      @manifest = create_manifest
    end

    describe "on existing manifest" do
      it "should cut a new Release for the Manifest" do
        get "/manifests/#{@manifest.name}"
        last_response.status.must_equal 200
      end
    end

    describe "on non-existing manifest" do
      it "should return created" do
        get "/manifests/non-existant"
        last_response.status.must_equal 404
      end
    end
  end

  describe "forking a manifest" do
    before do
      @manifest = create_manifest
      @release = create_release(:manifest_id => @manifest.id)

      post "/manifests/#{@manifest.name}/fork", { 'name' => 'fork' }.to_json
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
      @manifest = create_manifest

      post "/manifests/#{@manifest.name}/follow", { 'name' => 'follower', 'follower_override' => { 'other' => 'amazing' } }.to_json
      @follower = Manifest.where(:name => 'follower').first
    end

    it "should create a follower" do
      @follower.followee.must_equal @manifest

      post "/manifests/#{@manifest.name}/release", { 'other' => 'something', 'noir' => 'awesome' }.to_json

      @follower.reload
      @follower.releases.last.components.must_equal({ 'other' => 'amazing', 'noir' => 'awesome' })
    end

    it "should return created" do
      last_response.status.must_equal 201
    end

    describe "with an updated manifest" do
      before do
        put "/manifests/#{@follower.name}", { 'follower_override' => { 'other' => 'shamazing' } }.to_json
        post "/manifests/#{@follower.name}/release", { 'other' => 'something', 'noir' => 'awesome' }.to_json

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
      @manifest = create_manifest

      delete "/manifests/#{@manifest.name}"
    end

    it "should destroy the manifest" do
      Manifest[@manifest.id].must_be_nil
    end
  end
end
