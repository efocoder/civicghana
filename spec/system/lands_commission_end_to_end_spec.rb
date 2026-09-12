require "rails_helper"

RSpec.describe "Lands Commission release gate", type: :system do
  before do
    driven_by :rack_test
    Rails.application.load_seed
  end

  it "completes the configured case, evidence, action, draft, and grounded AI flow" do
    service = PublicService.find_by!(slug: "official-consolidated-search")

    visit public_service_path(service.slug)
    expect(page).to have_content("Official search result: 14 days after payment")
    click_link "Start checking my case"

    fill_in "case_application_completed_on", with: "2026-07-30"
    fill_in "case_payment_date", with: "2026-07-27"
    fill_in "case_portal_created_on", with: "2026-07-27"
    select "Greater Accra", from: "case_region"
    service.process_steps.active.each do |step|
      find("select[name='milestones[#{step.id}]']").select("Pending")
    end
    fill_in "case_observation_observed_on", with: "2026-08-20"
    click_button "Assess my application"

    kase = Case.order(:created_at).last
    expect(page).to have_content("Published timeframe exceeded")

    page.driver.submit :post, case_observations_path(kase), {
      case_observation: {
        observation_type: "phone", observed_on: "2026-09-05",
        progress_claim: "near_completion", summary: "The service is near completion."
      }
    }
    page.driver.submit :post, case_observations_path(kase), {
      case_observation: { observation_type: "portal", observed_on: "2026-09-10" },
      milestones: service.process_steps.active.to_h { |step| [step.id.to_s, "Pending"] }
    }

    visit case_path(kase)
    expect(page).to have_content("Possible stale public status")
    expect(page).to have_content("Request written clarification")

    visit new_case_case_action_path(kase, action_type: "clarification")
    expect(page).to have_content("Draft")
    expect(page).to have_content("Land Act, 2020")

    allow(Ai::Client).to receive(:generate).and_return(
      "The verified source says the official search result is due within fourteen days after payment (Land Act, 2020 (Act 1036), Section 222)."
    )
    page.driver.submit :post, ask_assistant_path, {
      service_slug: service.slug,
      question: "official search fourteen days payment"
    }

    payload = JSON.parse(page.body)
    expect(payload.fetch("answer")).to include("fourteen days", "Section 222")
    expect(payload.fetch("sources").map { |source| source.fetch("title") }).to include("Land Act, 2020 (Act 1036)")
  end
end
