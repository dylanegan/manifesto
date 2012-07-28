class Release < Sequel::Model
  attr_accessor :initial

  many_to_one :manifest

  plugin :json_serializer
  plugin :serialization, :json, :components, :diff
  plugin :timestamps
  plugin :validation_helpers

  def initial?
    !!initial
  end

  # Public: The stored manifest
  #
  # Examples
  #
  #   Release[1].stored_manifest
  #   # => Fog::Storage::AWS::File
  #
  # Returns a Fog::Storage::AWS::File object
  def stored_manifest
    @stored_manifest ||= directory.files.get("#{manifest.name}-#{version}.json")
  end

  private

  # Private: Perform tasks before validation
  def before_validation
    set_version
    super
  end

  # Private: Perform tasks before creation
  def after_create
    create_stored_manifest
    super
  end

  # Private: Perform tasks after destroy
  def after_destroy
    destroy_stored_manifest
    ensure_current_if_current
    super
  end

  # Private: Create the stored manifest on S3
  def create_stored_manifest
    unless stored_manifest
      @stored_manifest = directory.files.new(:body => components.to_json, :key => "#{manifest.name}-#{version}.json", :content_type => 'application/json')
      @stored_manifest.acl = 'public-read'
      @stored_manifest.save
      create_current_manifest
    end
  end

  # Private: Copy the stored manifest as the current release
  #          if this release is the latest
  def create_current_manifest
    if stored_manifest && latest_version == version
      retries = 0
      begin
        stored_manifest.copy(Manifesto.bucket, "#{manifest.name}-current.json", { 'x-amz-acl' => 'public-read' })
      rescue Excon::Errors::NotFound => error
        raise error unless error.response.body =~ /NoSuchKey/ &&
                           (retries += 1) < 5
        sleep 0.5
        retry
      end
    end
  end

  # Private: Destroy the stored manifest on S3
  def destroy_stored_manifest
    if stored_manifest
      stored_manifest.destroy
      @stored_manifest = nil
    end
  end

  # Private: The directory used for storing the manifest
  #
  # Returns a Fog::Storage::AWS::Directory object
  def directory
    return @directory if @directory

    unless @directory = Manifesto.storage.directories.get(Manifesto.bucket)
      @directory = Manifesto.storage.directories.create(:key => Manifesto.bucket)
      sleep 1 unless Fog.mocking?
    end

    @directory
  end

  # Private: Ensure the current release is the right release
  def ensure_current_if_current
    manifest.reload
    if current = manifest.current
      current.stored_manifest.copy(Manifesto.bucket, "#{manifest.name}-current.json", { 'x-amz-acl' => 'public-read' }) unless current.version > self.version
    elsif current = directory.files.get("#{manifest.name}-current.json")
      current.destroy
    end
  end

  # Private: The latest version for a given manifest
  def latest_version
    (Release.where(:manifest_id => manifest_id).max(:version) || 0)
  end

  # Private: Set the release version
  def set_version
    self.version ||= latest_version + 1
  end

  # Private: Validate the Release
  def validate
    super
    validates_presence :components unless initial?
    validates_presence :version
  end

  def self.log(data, exception, &block)
    Manifesto.log({release: true}.merge(data), exception, &block)
  end

  def log(data, exception, &block)
    self.class.log({release_id: id}.merge(data), exception, &block)
  end
end
