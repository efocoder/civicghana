class ProgressClaim < ApplicationRecord
  scope :active, -> { where(active: true).order(:name) }
  validates :code, :name, presence: true, uniqueness: true
end
