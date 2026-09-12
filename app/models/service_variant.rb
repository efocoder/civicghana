class ServiceVariant < ApplicationRecord
  belongs_to :public_service
  has_many :requirements, dependent: :restrict_with_error
  has_many :service_fees, dependent: :restrict_with_error

  normalizes :slug, with: ->(slug) { slug.to_s.strip.downcase }
  validates :name, :slug, presence: true
  validates :slug, uniqueness: { scope: :public_service_id }, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }
end
