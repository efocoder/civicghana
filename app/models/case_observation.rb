class CaseObservation < ApplicationRecord
  belongs_to :case
  has_many :case_milestone_observations, dependent: :destroy

  enum :observation_type, {
    portal: "portal",
    phone: "phone",
    in_person: "in_person",
    email: "email",
    letter: "letter",
    other: "other"
  }, validate: true

  validates :observed_on, presence: true
  validate :observed_on_not_in_future
  validate :observed_on_not_before_application_completed

  private

  def observed_on_not_in_future
    return unless observed_on && observed_on > Date.current

    errors.add(:observed_on, "cannot be in the future")
  end

  def observed_on_not_before_application_completed
    completed = self.case&.application_completed_on
    return unless observed_on && completed && observed_on < completed

    errors.add(:observed_on, "cannot be earlier than the application completion date")
  end
end
