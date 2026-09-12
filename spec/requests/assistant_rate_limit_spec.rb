require "rails_helper"

RSpec.describe "Assistant rate limiting", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:service) { create(:public_service) }

  it "uses a rolling minute window instead of a lifetime session count" do
    20.times do
      post ask_assistant_path, params: { service_slug: service.slug, question: "hello" }
      expect(response).to have_http_status(:ok)
    end

    post ask_assistant_path, params: { service_slug: service.slug, question: "hello" }
    expect(response).to have_http_status(:too_many_requests)

    travel 61.seconds do
      post ask_assistant_path, params: { service_slug: service.slug, question: "hello" }
      expect(response).to have_http_status(:ok)
    end
  end
end
