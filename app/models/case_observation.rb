class CaseObservation < ApplicationRecord
  belongs_to :case
  belongs_to :reported_process_step, class_name: "ProcessStep", optional: true
  has_many :case_milestone_observations, dependent: :destroy

  enum :observation_type, {
    portal: "portal",
    phone: "phone",
    in_person: "in_person",
    email: "email",
    letter: "letter",
    sms: "sms",
    other: "other"
  }, validate: true

  enum :progress_claim, {
    unspecified: "unspecified",
    public_milestone: "public_milestone",
    near_completion: "near_completion",
    completed: "completed",
    other_claim: "other"
  }, validate: { allow_nil: true }

  validates :observed_on, presence: true
  validates :summary, length: { maximum: 1000 }, allow_blank: true
  validate :observed_on_not_in_future
  validate :observed_on_not_before_application_completed
  validate :non_portal_requires_progress_claim
  validate :public_milestone_requires_process_step
  validate :reported_process_step_matches_service

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

  def non_portal_requires_progress_claim
    return if portal?
    return if progress_claim.present?

    errors.add(:progress_claim, "is required for non-portal evidence")
  end

  def public_milestone_requires_process_step
    return unless public_milestone?
    return if reported_process_step_id.present?

    errors.add(:reported_process_step_id, "is required when progress claim is a public milestone")
  end

  def reported_process_step_matches_service
    return unless reported_process_step && self.case
    return if reported_process_step.public_service_id == self.case.public_service_id

    errors.add(:reported_process_step, "must belong to the case service")
  end
end
