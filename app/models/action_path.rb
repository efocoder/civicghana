class ActionPath < ApplicationRecord
  include CatalogTranslatable
  enum :action_type, {
    check: "check",
    verify: "verify",
    agency_follow_up: "agency_follow_up",
    information_request: "information_request",
    external_escalation: "external_escalation"
  }, validate: true

  belongs_to :public_service
  belongs_to :source

  validates :title, :instructions, presence: true
  validates :sequence, numericality: { only_integer: true, greater_than: 0 },
    uniqueness: { scope: :public_service_id }
end
