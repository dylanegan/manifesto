require 'fog'
require 'scrolls'

module Manifesto
  def self.bucket
    @bucket ||= ENV['S3_BUCKET'] || "release-manifests-#{rand(1_000_000)}"
  end

  # Public: Log data through Scrolls
  #
  # Example
  #
  #   Fog::Bouncer.log(data_one: true, data_two: true)
  #
  # Returns nothing
  def self.log(data, &block)
    log! unless logging?
    Scrolls.log({ 'fog-bouncer' => true, 'pretending' => pretending? }.merge(data), &block)
  end

  # Public: Start the Scrolls logger
  #
  # Example
  #
  #   Fog::Bouncer.log!
  #
  # Returns nothing
  def self.log!
    Scrolls::Log.start(logger)
    @logging = true
  end

  # Public: The logging location
  #
  # Returns an Object
  def self.logger
    @logger ||= STDOUT
  end

  # Public: Set the logging location
  #
  # Returns nothing
  def self.logger=(logger)
    @logger = logger
  end

  # Public: Check the logging state
  #
  # Example
  #
  #   Fog::Bouncer.logging?
  #   # => true
  #
  # Returns false or true if logging has been started
  def self.logging?
    @logging ||= false
  end

  def self.storage
    @storage ||= Fog::Storage.new({
      :provider => 'AWS',
      :aws_access_key_id => ENV['AWS_ACCESS_KEY_ID'],
      :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
    })
  end
end

require 'securerandom'
require 'json'
require 'sequel'

