module CatalogTranslatable
  extend ActiveSupport::Concern

  included do
    has_many :catalog_translations, as: :translatable, dependent: :destroy
  end

  def catalog_translation(locale = I18n.locale)
    catalog_translations.find_by(locale: locale.to_s) ||
      catalog_translations.find_by(locale: I18n.default_locale.to_s)
  end

  def translated_name(locale = I18n.locale)
    catalog_translation(locale)&.name.presence || respond_to?(:name) && name
  end

  def translated_description(locale = I18n.locale)
    catalog_translation(locale)&.description.presence || respond_to?(:description) && description
  end

  def translated_title(locale = I18n.locale)
    catalog_translation(locale)&.title.presence || respond_to?(:title) && title
  end

  def translated_summary(locale = I18n.locale)
    catalog_translation(locale)&.summary.presence || respond_to?(:summary) && summary
  end

  def translated_instructions(locale = I18n.locale)
    catalog_translation(locale)&.instructions.presence || respond_to?(:instructions) && instructions
  end
end
