require "rails_helper"

RSpec.describe CatalogTranslation, type: :model do
  let(:service) { create(:public_service) }

  it "requires a supported locale" do
    translation = service.catalog_translations.build(locale: "xx", name: "Test")
    expect(translation).not_to be_valid
  end

  it "provides translated values with English fallback" do
    service.catalog_translations.create!(locale: "en", name: "English name", description: "English description")
    service.catalog_translations.create!(locale: "tw", name: "Twi name", description: "Twi description")

    expect(service.translated_name(:tw)).to eq("Twi name")
    expect(service.translated_description(:tw)).to eq("Twi description")
    expect(service.translated_name(:fr)).to eq("English name")
  end
end
