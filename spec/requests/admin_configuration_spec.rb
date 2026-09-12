require "rails_helper"

RSpec.describe "Admin configuration", type: :request do
  let(:headers) do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials("admin", "secret")
    { "HTTP_AUTHORIZATION" => credentials }
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ADMIN_USERNAME").and_return("admin")
    allow(ENV).to receive(:[]).with("ADMIN_PASSWORD").and_return("secret")
  end

  it "rejects unauthenticated access" do
    get admin_agencies_path
    expect(response).to have_http_status(:unauthorized)
  end

  it "renders every configuration collection for an authenticated admin" do
    [admin_agencies_path, admin_public_services_path, admin_process_steps_path,
      admin_status_options_path, admin_service_rules_path, admin_sources_path,
      admin_service_sources_path, admin_action_resources_path, admin_source_chunks_path].each do |path|
      get path, headers: headers
      expect(response).to have_http_status(:ok), "expected #{path} to render"
    end
  end

  it "creates and updates an agency" do
    country = create(:country)
    post admin_agencies_path, headers: headers, params: {
      institution: {
        country_id: country.id, name: "Configurable Agency", slug: "configurable-agency",
        short_name: "CA", description: "Configured by an administrator.",
        website_url: "https://agency.example.gov.gh", active: true
      }
    }

    agency = Institution.find_by!(slug: "configurable-agency")
    expect(response).to redirect_to(admin_agencies_path)

    patch admin_agency_path(agency), headers: headers,
      params: { institution: { short_name: "CAG" } }
    expect(agency.reload.short_name).to eq("CAG")
  end
end
