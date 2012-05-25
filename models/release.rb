class Release < Sequel::Model
  many_to_one :manifest

  plugin :json_serializer
  plugin :serialization, :json, :components, :diff
  plugin :timestamps
  plugin :validation_helpers

  def stored_manifest
    @stored_manifest ||= directory.files.get("#{manifest.name}-#{version}.json")
  end

  def validate
    super
    validates_presence [:components, :version]
  end

  private

  def before_validation
    set_version
    super
  end

  def after_create
    create_stored_manifest
    super
  end

  def after_destroy
    destroy_stored_manifest
    ensure_current_if_current
    super
  end

  def create_stored_manifest
    unless stored_manifest
      @stored_manifest = directory.files.new(:body => components.to_json, :key => "#{manifest.name}-#{version}.json", :content_type => 'application/json')
      @stored_manifest.acl = 'public-read'
      @stored_manifest.save
      @stored_manifest.copy(Manifesto.bucket, "#{manifest.name}-current.json", { 'x-amz-acl' => 'public-read' }) if latest_version == version
    end
  end

  def destroy_stored_manifest
    stored_manifest.destroy
    @stored_manifest = nil
  end

  def directory
    @directory ||= Manifesto.storage.directories.get(Manifesto.bucket) || Manifesto.storage.directories.create(:key => Manifesto.bucket)
  end

  def ensure_current_if_current
    manifest.reload
    if current = manifest.current
      current.stored_manifest.copy(Manifesto.bucket, "#{manifest.name}-current.json", { 'x-amz-acl' => 'public-read' }) unless current.version > self.version
    else
      directory.files.get("#{manifest.name}-current.json").destroy
    end
  end

  def latest_version
    (Release.where(:manifest_id => manifest_id).max(:version) || 0)
  end

  def set_version
    self.version ||= latest_version + 1
  end

  def self.log(data, exception, &block)
    Manifesto.log({release: true}.merge(data), exception, &block)
  end

  def log(data, exception, &block)
    self.class.log({release_id: id}.merge(data), exception, &block)
  end
end
