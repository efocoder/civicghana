class CaseMilestoneObservation < ApplicationRecord
  belongs_to :case_observation
  belongs_to :process_step

  validates :status, presence: true
  validates :process_step_id, uniqueness: { scope: :case_observation_id }
end
