require "rails_helper"

RSpec.describe "Hackathon readiness", type: :request do
  before { Rails.application.load_seed }

  it "renders the public catalogue and controls in Twi while retaining authoritative source names" do
    get root_path, params: { locale: "tw" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Nnwuma a ɛwɔ hɔ", "Twi")

    get public_service_path("deed-registration"), params: { locale: "tw" }
    expect(response.body).to include("Deed Kyerɛw Din", "Wɔde saa nkyerɛaseɛ yi boa")
  end

  it "creates Deed and First Registration cases without inventing portal milestones" do
    %w[deed-registration registration-of-title].each do |slug|
      service = PublicService.find_by!(slug: slug)

      expect {
        post cases_path, params: {
          case: {
            public_service_id: service.id,
            application_completed_on: "2026-07-01",
            region: "Greater Accra"
          }
        }
      }.to change(Case, :count).by(1).and change(CaseObservation, :count).by(0)

      expect(response).to redirect_to(case_path(Case.order(:created_at).last))
      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Recommended next step")
      expect(service).not_to be_tracks_portal_milestones
    end
  end

  it "preserves a selected locale through form redirects" do
    service = PublicService.find_by!(slug: "deed-registration")
    post cases_path(locale: "tw"), params: {
      case: { public_service_id: service.id, application_completed_on: "2026-07-01", region: "Greater Accra" }
    }

    expect(response.location).to include("locale=tw")
  end

  it "exposes source provenance and the working-day estimate caveat" do
    get public_service_path("registration-of-title")

    expect(response.body).to include("Last verified", "Ghana Lands Commission")
    expect(response.body).to include("Ghana public holidays are not yet included")
  end
end
