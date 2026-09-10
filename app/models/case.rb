class Case < ApplicationRecord
  belongs_to :public_service
  has_many :case_observations, dependent: :destroy

  validates :region, presence: true
  validates :region, inclusion: { in: CivicRoute::REGIONS }
  validates :application_completed_on, presence: true
  validate :application_completed_on_not_in_future
  validate :payment_date_not_in_future
  validate :portal_created_on_not_in_future

  def public_id
    id
  end

  private

  def application_completed_on_not_in_future
    return unless application_completed_on && application_completed_on > Date.current

    errors.add(:application_completed_on, "cannot be in the future")
  end

  def payment_date_not_in_future
    return unless payment_date && payment_date > Date.current

    errors.add(:payment_date, "cannot be in the future")
  end

  def portal_created_on_not_in_future
    return unless portal_created_on && portal_created_on > Date.current

    errors.add(:portal_created_on, "cannot be in the future")
  end

end
