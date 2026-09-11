class ProcessStep < ApplicationRecord
  include CatalogTranslatable
  belongs_to :public_service
  belongs_to :source, optional: true

  validates :name, :description, presence: true
  validates :sequence, numericality: { only_integer: true, greater_than: 0 },
    uniqueness: { scope: :public_service_id }
end
