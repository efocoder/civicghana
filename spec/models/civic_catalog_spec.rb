require "rails_helper"

RSpec.describe "Civic service catalogue", type: :model do
  let(:agency) { create(:institution) }
  let(:service) { create(:public_service, institution: agency) }

  it "orders active organizational units" do
    later = OrganizationalUnit.create!(institution: agency, name: "Later", code: "L", position: 2)
    earlier = OrganizationalUnit.create!(institution: agency, name: "Earlier", code: "E", position: 1)

    expect(OrganizationalUnit.active.ordered).to eq([ earlier, later ])
  end

  it "supports service variants and ordered requirements" do
    variant = ServiceVariant.create!(public_service: service, name: "Express", slug: "express")
    second = Requirement.create!(public_service: service, service_variant: variant, category: "document", title: "Second", position: 2)
    first = Requirement.create!(public_service: service, category: "document", title: "First", position: 1)

    expect(service.requirements.active.ordered).to eq([ first, second ])
  end

  it "rejects case tracking for a non-trackable service" do
    service.support_level = :guided
    service.case_enabled = true

    expect(service).not_to be_valid
    expect(service.errors[:case_enabled]).to include("requires trackable support")
  end

  it "accepts a source-backed fee with an unknown amount" do
    fee = ServiceFee.new(public_service: service, source: create(:source), name: "Published fee", amount: nil)

    expect(fee).to be_valid
  end
end
