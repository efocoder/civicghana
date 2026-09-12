require "rails_helper"

RSpec.describe CatalogTranslation, type: :model do
  let(:service) { create(:public_service) }

  it "requires a supported locale" do
    translation = service.catalog_translations.build(locale: "xx", name: "Test")
    expect(translation).not_to be_valid
  end

  it "provides translated values with English fallback" do
    service.catalog_translations.create!(locale: "en", name: "English name", description: "English description")
    service.catalog_translations.create!(locale: "fr", name: "Nom français", description: "Description française")

    expect(service.translated_name(:fr)).to eq("Nom français")
    expect(service.translated_description(:fr)).to eq("Description française")
    expect(service.translated_name(:de)).to eq("English name")
  end
end
