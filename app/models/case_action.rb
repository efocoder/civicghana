class CaseAction < ApplicationRecord
  belongs_to :case
  belongs_to :action_resource, optional: true

  enum :action_type, {
    monitor: "monitor",
    clarification: "clarification",
    complaint: "complaint",
    rti: "rti",
    chraj: "chraj"
  }, validate: true

  enum :status, {
    recommended: "recommended",
    prepared: "prepared",
    taken: "taken",
    responded: "responded",
    resolved: "resolved",
    unresolved: "unresolved",
    cancelled: "cancelled"
  }, validate: true

  enum :outcome, {
    awaiting_response: "awaiting_response",
    received_response: "received_response",
    outcome_resolved: "resolved",
    outcome_unresolved: "unresolved"
  }, validate: { allow_nil: true }

  validates :recommended_on, presence: true
  validate :taken_on_not_in_future

  scope :active, -> { where.not(status: %w[cancelled resolved]) }
  scope :for_type, ->(type) { where(action_type: type) }

  private

  def taken_on_not_in_future
    return unless taken_on && taken_on > Date.current

    errors.add(:taken_on, "cannot be in the future")
  end
end
