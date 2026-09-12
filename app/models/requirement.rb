class Requirement < ApplicationRecord
  include CatalogTranslatable
  belongs_to :public_service
  belongs_to :service_variant, optional: true
  belongs_to :source, optional: true

  validates :category, :title, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :variant_belongs_to_service

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :title) }

  private

  def variant_belongs_to_service
    return unless service_variant && public_service && service_variant.public_service_id != public_service_id

    errors.add(:service_variant, "must belong to the same public service")
  end
end
