require "manifesto/core_ext/hash/deep_merge"

class Manifest < Sequel::Model
  one_to_many :followers, :class => self, :key => :followee_id
  many_to_one :followee, :class => self, :key => :followee_id
  one_to_many :releases

  plugin :json_serializer
  plugin :serialization, :json, :follower_override
  plugin :timestamps
  plugin :validation_helpers

  def add_follower(attributes)
    fork(attributes.merge(:followee_id => self.id))
  end

  def fork(attributes)
    forked = Manifest.new
    forked.set_only(attributes, [:name, :follower_override, :followee_id])
    forked.save
    forked.release(current.components) if current
    forked
  end

  def current
    releases_dataset.order(:version).last
  end

  def release(components = {}, scope = nil)
    components = scope_for(components, scope) if scope
    components = merge_follower(components)
    components, diff = merge_current(components)

    return false if components.empty?

    components = components.delete_if {|k, v| v.nil? }
    release = add_release(:components => components, :diff => diff)
    update_followers(diff ? diff : components)
    release
  end

  private

  def before_destroy
    releases.each { |r| r.destroy }
  end

  def merge_follower(components)
    follower_override ? components.deep_merge(follower_override) : components
  end

  def merge_current(components)
    if current && current_components = current.components
      diff = components
      components = current_components.deep_merge(components)
      components = {} if components == current.components
    end

    [components, diff]
  end

  def scope_for(components, scope)
    scope.split('/').reverse.inject({}) do |hash, s|
      hash = { s => components }
      components = hash
      hash
    end
  end

  def validate
    super
    validates_presence [:name]
    validates_unique   :name
  end

  def self.log(data, exception, &block)
    Manifesto.log({manifest: true}.merge(data), exception, &block)
  end

  def log(data, exception, &block)
    self.class.log({manifest_id: id, name: name}.merge(data), exception, &block)
  end

  def update_followers(components)
    followers.each do |follower|
      follower.release(components)
    end
  end
end
