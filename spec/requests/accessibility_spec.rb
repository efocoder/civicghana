require "rails_helper"

RSpec.describe "Accessibility settings", type: :request do
  it "provides a globally available, labelled settings dialog" do
    get root_path

    page = Nokogiri::HTML(response.body)
    button = page.at_css("button[aria-controls='accessibility-settings']")
    dialog = page.at_css("#accessibility-settings[role='dialog']")

    expect(response).to have_http_status(:ok)
    expect(button.text.strip).to eq("Accessibility")
    expect(button["aria-expanded"]).to eq("false")
    expect(dialog["aria-labelledby"]).to eq("accessibility-settings-title")
    expect(dialog["hidden"]).not_to be_nil
    expect(dialog.css("input[type='radio'][name='accessibility-text-size']").map { |input| input["value"] }).to eq(%w[normal large extra-large])
    expect(dialog.css("input[type='checkbox']").length).to eq(5)
  end

  it "renders every accessibility label in each supported locale" do
    I18n.available_locales.each do |locale|
      get root_path(locale: locale)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("accessibility.control", locale: locale))
      expect(response.body).to include(I18n.t("accessibility.extra_large", locale: locale))
      page = Nokogiri::HTML(response.body)
      expect(page.at_css("html")["data-accessibility-unavailable-label-value"]).to eq(I18n.t("accessibility.unavailable", locale: locale))
      expect(response.body).not_to include("Translation missing")
    end
  end

  it "keeps critical service filters visibly labelled" do
    get root_path

    page = Nokogiri::HTML(response.body)
    expect(page.at_css("label[for='q']").text).to include("Search services")
    expect(page.at_css("label[for='agency_id']").text).to include("Agency")
    expect(page.at_css("label[for='unit_id']").text).to include("Unit")
  end
end
