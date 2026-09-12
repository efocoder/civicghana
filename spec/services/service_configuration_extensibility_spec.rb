require "rails_helper"

RSpec.describe "service configuration extensibility", type: :request do
  let(:country) { create(:country) }
  let(:agency) { create(:institution, country: country, name: "Test Records Agency") }
  let(:service) { create(:public_service, institution: agency, name: "Certificate Check", slug: "certificate-check") }
  let(:source) { create(:source, title: "Certificate Rules", url: "https://example.gov.gh/certificate-rules") }

  before do
    create(:process_step, public_service: service, name: "Registry review", sequence: 1)
    create(:process_step, public_service: service, name: "Certificate issuance", sequence: 2)
    create(:portal_status, public_service: service, code: "queued", name: "Queued", position: 1)
    create(:portal_status, public_service: service, code: "issued", name: "Issued", position: 2)
    create(:service_rule, public_service: service, source: source, value: 3, unit: "days", anchor_event: :completed_application)
    create(:service_source, public_service: service, source: source, primary: true)
    create(:source_chunk, public_service: service, source: source, content: "A certificate check takes three days after completion.")
  end

  it "resolves a different rule duration and anchor by service" do
    kase = create(:case, public_service: service, application_completed_on: Date.new(2026, 9, 1))
    result = CaseAssessment::Evaluate.call(case_record: kase, assessment_date: Date.new(2026, 9, 5))[:rule]

    expect(result.published_days).to eq(3)
    expect(result.deadline).to eq(Date.new(2026, 9, 4))
    expect(result.assessment_state).to eq(:timeframe_exceeded)
  end

  it "renders only this service's steps and statuses in its case form" do
    get new_case_path(service_slug: service.slug)

    expect(response.body).to include("Registry review", "Certificate issuance", "Queued", "Issued")
    expect(response.body).not_to include("Quality Control and Coordinate Entry")
  end

  it "retrieves only chunks explicitly scoped to this service" do
    other_service = create(:public_service)
    other_source = create(:source)
    create(:source_chunk, public_service: other_service, source: other_source,
      content: "A certificate check takes ninety days after completion.")

    result = Ai::Retrieval.call(query: "certificate check days completion", service: service)

    expect(result.chunks.map(&:public_service_id)).to all(eq(service.id))
    expect(result.context_text).to include("three days")
    expect(result.context_text).not_to include("ninety days")
  end
end
