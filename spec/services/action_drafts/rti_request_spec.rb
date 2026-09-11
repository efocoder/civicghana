require "rails_helper"

RSpec.describe ActionDrafts::RtiRequest do
  before { Rails.application.load_seed }

  let(:service) { PublicService.find_by!(slug: "official-consolidated-search") }

  let(:kase) do
    create(:case,
      public_service: service,
      application_completed_on: Date.new(2026, 7, 30))
  end

  it "generates subject with service name" do
    draft = described_class.call(case_record: kase, information_requested: "Current application status")

    expect(draft[:subject]).to include("Official / Consolidated Search")
  end

  it "includes institution name" do
    draft = described_class.call(case_record: kase, information_requested: "Current application status")

    expect(draft[:body]).to include("Lands Commission")
  end

  it "includes the information requested" do
    draft = described_class.call(case_record: kase, information_requested: "Current application status")

    expect(draft[:body]).to include("Current application status")
  end

  it "includes placeholder when information is blank" do
    draft = described_class.call(case_record: kase, information_requested: "")

    expect(draft[:body]).to include("[Describe the specific information you are seeking]")
  end

  it "does not predict RTI outcome" do
    draft = described_class.call(case_record: kase, information_requested: "Status")

    expect(draft[:body]).not_to include("will succeed")
    expect(draft[:body]).not_to include("will be granted")
  end
end
