class Case < ApplicationRecord
  belongs_to :public_service
  has_many :case_observations, dependent: :destroy
  has_many :case_actions, dependent: :destroy

  validates :region, presence: true, if: -> { public_service&.requires_region? }
  validate :region_is_configured_for_service
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

  def region_is_configured_for_service
    return if region.blank? || public_service.blank? || !public_service.requires_region?

    regions = public_service.institution.country.regions.active
    return if regions.none? # Factories may intentionally omit country catalog data.
    return if regions.exists?(name: region)

    errors.add(:region, "must be a configured region for this agency")
  end
end
