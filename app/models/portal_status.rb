class PortalStatus < ApplicationRecord
  belongs_to :public_service
  scope :active, -> { where(active: true).order(:position) }
  validates :code, :name, presence: true
  validates :code, uniqueness: { scope: :public_service_id }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
