require 'helper'

describe 'Release' do
  let(:manifest) { create_manifest }
  let(:release) { new_release(:manifest_id => manifest.id) }

  describe :components do
    it "should accept components" do
      release.components = {component: 'version'}.to_json
      release.valid?
      release.errors.wont_include('component')
    end
  end

  describe "on create" do
    before do
      release.save
    end

    it "should issue a version" do
      release.version.must_equal 2
    end

    it "should increment when issuing a version" do
      other_release = create_release(:manifest_id => manifest.id)
      other_release.version.must_equal 3
    end

    it "should increment given the manifest scope" do
      different_release = create_release(:manifest_id => create_manifest.id)
      different_release.version.must_equal 2
    end

    it "should store the release on S3" do
      r = Manifesto.storage.directories.get(Manifesto.bucket).files.get("#{release.manifest.name}-#{release.version}.json")
      r.body.must_equal release.components.to_json
      r.content_type.must_equal 'application/json'
      r.public_url.must_equal "https://#{Manifesto.bucket}.s3.amazonaws.com/#{release.manifest.name}-#{release.version}.json"
    end

    it "should set the current release on S3" do
      current = Manifesto.storage.directories.get(Manifesto.bucket).files.get("#{release.manifest.name}-current.json")
      current.body.must_equal release.components.to_json
      current.content_type.must_equal 'application/json'
      current.public_url.must_equal "https://#{Manifesto.bucket}.s3.amazonaws.com/#{release.manifest.name}-current.json"
    end
  end

  describe "private manifests" do
    before do
      ENV['PRIVATE_MANIFESTS'] = "true"
      release.save
    end

    after do
      ENV.delete('PRIVATE_MANIFESTS')
    end

    it "should store the release on S3 privately" do
      r = Manifesto.storage.directories.get(Manifesto.bucket).files.get("#{release.manifest.name}-#{release.version}.json")
      r.public_url.must_equal nil
    end

    it "should set the current release on S3 privatley" do
      current = Manifesto.storage.directories.get(Manifesto.bucket).files.get("#{release.manifest.name}-current.json")
      current.public_url.must_equal nil
    end
  end

  describe "on destroy" do
    before do
      @other_release = create_release(:manifest_id => manifest.id)
      release.save
      release.destroy
    end

    it "should destroy the release on S3" do
      release.stored_manifest.must_be_nil
    end

    it "should ensure the current release is correct" do
      @other_release.components.to_json.must_equal Manifesto.storage.directories.get(Manifesto.bucket).files.get("#{release.manifest.name}-current.json").body
    end

    it "should destroy all files if there is no release" do
      manifest.releases.each { |r| r.destroy }
      Manifesto.storage.directories.get(Manifesto.bucket).files.get("#{release.manifest.name}-current.json").must_be_nil
    end

    it "should not fail when S3 file is missing" do
      @other_release.stored_manifest.destroy
      Release[@other_release.id].destroy
      Release[@other_release.id].must_be_nil
    end
  end
end
