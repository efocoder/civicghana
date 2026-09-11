class Region < ApplicationRecord
  belongs_to :country
  has_many :cases, dependent: :restrict_with_error

  scope :active, -> { where(active: true) }
  validates :code, :name, presence: true
  validates :code, uniqueness: { scope: :country_id }
end
