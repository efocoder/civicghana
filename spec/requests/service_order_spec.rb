require "rails_helper"

RSpec.describe "Service ordering", type: :request do
  before { Rails.application.load_seed }

  it "displays Official / Consolidated Search first in the catalogue" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body.index("Official / Consolidated Search")).to be < response.body.index("Deed Registration")
  end

  it "uses Official / Consolidated Search as the default case service" do
    get new_case_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Official / Consolidated Search")
  end
end
