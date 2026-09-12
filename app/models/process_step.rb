class ProcessStep < ApplicationRecord
  include CatalogTranslatable
  belongs_to :public_service
  belongs_to :source, optional: true

  scope :active, -> { where(active: true).order(:position) }

  before_validation :synchronize_positions

  validates :name, :description, presence: true
  validates :position, numericality: { only_integer: true, greater_than: 0 },
    uniqueness: { scope: :public_service_id }
  validates :sequence, numericality: { only_integer: true, greater_than: 0 },
    uniqueness: { scope: :public_service_id }

  private

  def synchronize_positions
    self.position ||= sequence
    self.sequence ||= position
  end
end
