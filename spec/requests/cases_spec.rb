require "rails_helper"

RSpec.describe "Cases", type: :request do
  before { Rails.application.load_seed }

  describe "GET /cases/new" do
    it "loads successfully" do
      get new_case_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Check your application")
    end

    it "contains the trust notice" do
      get new_case_path

      expect(response.body).to include("CivicRoute does not access an agency")
    end

    it "links back to the service guide" do
      get new_case_path

      expect(response.body).to include(public_service_path("official-consolidated-search"))
    end

    it "does not contain development-phase wording" do
      get new_case_path

      expect(response.body).not_to include("Phase 1")
      expect(response.body).not_to include("Phase 2")
      expect(response.body).not_to include("coming in Phase")
      expect(response.body).not_to include("hackathon")
      expect(response.body).not_to include("sprint")
    end
  end
end
