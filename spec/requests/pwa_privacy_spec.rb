require "rails_helper"

RSpec.describe "PWA privacy boundary", type: :request do
  it "ships a service worker that caches public guides but excludes cases, saved data and admin pages" do
    get "/service-worker.js"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('url.pathname.startsWith("/public_services/")')
    expect(response.body).to include('url.pathname.startsWith("/cases")')
    expect(response.body).to include('url.pathname.startsWith("/saved")')
    expect(response.body).to include('url.pathname.startsWith("/admin")')
  end
end
