require "rails_helper"

RSpec.describe "Public services", type: :request do
  before { Rails.application.load_seed }

  describe "GET /" do
    it "lists the seeded service" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Official / Consolidated Search")
      expect(response.body).to include("Lands Commission")
    end
  end

  describe "GET /public_services/:slug" do
    it "shows the verified official-search rule and source provenance" do
      get public_service_path("official-consolidated-search")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("14 days after payment")
      expect(response.body).to include("Verified source")
      expect(response.body).to include("Section 222")
      expect(response.body).to include("oasl.gov.gh")
    end

    it "displays the Land Act source title" do
      get public_service_path("official-consolidated-search")

      expect(response.body).to include("Land Act, 2020 (Act 1036)")
    end

    it "includes the Start checking my case link" do
      get public_service_path("official-consolidated-search")

      expect(response.body).to include("Start checking my case")
      expect(response.body).to include(new_case_path)
    end

    it "does not contain development-phase wording" do
      get public_service_path("official-consolidated-search")

      expect(response.body).not_to include("Phase 1")
      expect(response.body).not_to include("Phase 2")
      expect(response.body).not_to include("coming in Phase")
    end
  end
end
