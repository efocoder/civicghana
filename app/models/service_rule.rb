class ServiceRule < ApplicationRecord
  enum :rule_type, {
    expected_duration_days: "expected_duration_days",
    requires_payment_date: "requires_payment_date",
    complaint_available: "complaint_available",
    rti_guidance_available: "rti_guidance_available",
    admin_justice_guidance: "admin_justice_guidance",
    source_review_interval: "source_review_interval"
  }, validate: true

  enum :anchor_event, {
    payment: "payment",
    completed_application: "completed_application",
    portal_created: "portal_created"
  }, validate: true

  belongs_to :public_service
  belongs_to :source

  alias_attribute :value, :duration_value
  alias_attribute :unit, :duration_unit

  validates :value, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :duration_unit, :effective_from, :verified_at, presence: true
  validate :effective_period_is_valid

  scope :verified, -> { where(active: true).where.not(verified_at: nil) }
  scope :effective_on, ->(date) {
    where("service_rules.effective_from <= ?", date)
      .where("service_rules.effective_to IS NULL OR service_rules.effective_to >= ?", date)
  }

  private

  def effective_period_is_valid
    return unless effective_from && effective_to && effective_to < effective_from

    errors.add(:effective_to, "must be on or after the effective from date")
  end
end
