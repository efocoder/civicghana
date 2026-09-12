class ServiceFee < ApplicationRecord
  belongs_to :public_service
  belongs_to :service_variant, optional: true
  belongs_to :source

  validates :name, :currency, :calculation_type, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :effective_period_is_valid
  validate :variant_belongs_to_service

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }

  private

  def effective_period_is_valid
    errors.add(:effective_to, "must be on or after effective from") if effective_from && effective_to && effective_to < effective_from
  end

  def variant_belongs_to_service
    return unless service_variant && public_service && service_variant.public_service_id != public_service_id

    errors.add(:service_variant, "must belong to the same public service")
  end
end
