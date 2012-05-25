def new_api_key(params = {})
  APIKey.new({
    :username => "api-key-#{rand(1_000)}"
  }.merge(params))
end

def create_api_key(params = {})
  api_key = new_api_key(params)
  api_key.save
  api_key
end

def new_manifest(params = {})
  Manifest.new({
    :name => "manifest-#{rand(1_000)}"
  }.merge(params))
end

def create_manifest(params = {})
  manifest = new_manifest(params)
  manifest.save
  manifest
end

def new_release(params = {})
  Release.new({
    :components => { 'component' => '1' }
  }.merge(params))
end

def create_release(params = {})
  release = new_release(params)
  release.save
  release
end
