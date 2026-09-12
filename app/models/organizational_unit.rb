class OrganizationalUnit < ApplicationRecord
  include CatalogTranslatable
  belongs_to :institution
  has_many :public_services, dependent: :restrict_with_error

  validates :name, :code, presence: true
  validates :code, uniqueness: { scope: :institution_id }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }

  alias_attribute :agency_id, :institution_id
  alias_method :agency, :institution
end
