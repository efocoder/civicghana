class CatalogTranslation < ApplicationRecord
  belongs_to :translatable, polymorphic: true

  validates :locale, presence: true, inclusion: { in: %w[en tw fr ee] }
  validates :locale, uniqueness: { scope: %i[translatable_type translatable_id] }
end
