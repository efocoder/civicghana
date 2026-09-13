class CatalogTranslation < ApplicationRecord
  belongs_to :translatable, polymorphic: true

  validates :locale, presence: true, inclusion: { in: ->(_) { I18n.available_locales.map(&:to_s) } }
  validates :locale, uniqueness: { scope: %i[translatable_type translatable_id] }
end
