class APIKey < Sequel::Model
  plugin :timestamps
  plugin :validation_helpers

  def self.unexpired
    where("expires_at > ?", Time.now)
  end

  private

  def before_validation
    set_key
    validates_format /[a-f0-9]{64}/, :key
    set_expiration
    super
  end

  def validate
    super
    validates_presence [:username]
    expires_at_must_be_within_30_days
  end

  def expires_at_must_be_within_30_days
    if expires_at.nil?
      errors.add(:expires_at, "must be set")
    elsif new? && expires_at < Time.now
      errors.add(:expires_at, "can't be in the past")
    elsif expires_at > Time.now + 2_592_000
      errors.add(:expires_at, "must be within 30 days")
    end
  end

  def set_expiration
    self.expires_at ||= Time.now + 2_592_000
  end

  def set_key
    self.key ||= SecureRandom.hex(32)
  end
end
