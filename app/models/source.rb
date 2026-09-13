class Source < ApplicationRecord
  include CatalogTranslatable
  alias_attribute :authority_type, :source_type
  alias_attribute :section_label, :provision
  alias_attribute :verified_at, :last_verified_at

  enum :authority_type, {
    legislation: "legislation",
    official_service: "official_service",
    regulator_guidance: "regulator_guidance",
    oversight_body: "oversight_body"
  }, validate: true

  has_many :service_rules, dependent: :restrict_with_error
  has_many :process_steps, dependent: :restrict_with_error
  has_many :action_paths, dependent: :restrict_with_error
  has_many :source_chunks, dependent: :destroy
  has_many :service_sources, dependent: :destroy
  has_many :public_services, through: :service_sources


  validates :publisher, :title, :url, :summary, :verified_at, :content_hash, presence: true
  validates :authority_level, inclusion: { in: %w[primary official regulatory oversight] }, allow_blank: true
  validates :url, uniqueness: true, format: URI::DEFAULT_PARSER.make_regexp(%w[http https])
  validates :content_hash, format: { with: /\A[0-9a-f]{64}\z/ }
  validate :effective_period_is_valid

  scope :verified, -> { where(active: true).where.not(last_verified_at: nil) }
  scope :requiring_review, -> { where(review_required: true).or(where(review_due_at: ..Time.current)) }

  def verification_overdue?
    review_due_at.present? && review_due_at <= Time.current
  end

  def url_unavailable?
    last_checked_at.present? && (http_status.blank? || http_status >= 400)
  end

  private

  def effective_period_is_valid
    return unless effective_from && effective_to && effective_to < effective_from

    errors.add(:effective_to, "must be on or after the effective from date")
  end
end
