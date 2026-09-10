require "rails_helper"

RSpec.describe "Public service guide", type: :system do
  before do
    driven_by :rack_test
    Rails.application.load_seed
  end

  it "presents the official rule as a verified fact" do
    visit public_service_path("official-consolidated-search")

    expect(page).to have_content("Official search result: 14 days after payment")
    expect(page).to have_content("Verified source")
    expect(page).to have_link("Read the authoritative source", href: /oasl\.gov\.gh/)
  end

  it "displays the Land Act source title" do
    visit public_service_path("official-consolidated-search")

    expect(page).to have_content("Land Act, 2020 (Act 1036)")
    expect(page).to have_content("Section 222")
    expect(page).to have_content("Republic of Ghana")
  end

  it "navigates to the case-check page" do
    visit public_service_path("official-consolidated-search")
    click_link "Start checking my case"

    expect(page).to have_current_path(new_case_path)
    expect(page).to have_content("Check your application")
    expect(page).to have_content("CivicRoute does not access the Lands Commission")
  end
end
