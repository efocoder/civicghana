class PortalStatus < ApplicationRecord
  belongs_to :public_service
  scope :active, -> { where(active: true).order(:position) }
  validates :code, :name, presence: true
  validates :code, uniqueness: { scope: :public_service_id }
end
