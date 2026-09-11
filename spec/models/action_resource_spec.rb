require "rails_helper"

RSpec.describe ActionResource, type: :model do
  subject(:resource) { build(:action_resource) }

  it { is_expected.to belong_to(:institution) }
  it { is_expected.to belong_to(:source).optional }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:purpose) }

  it "accepts valid resource_type values" do
    %w[contact complaint rti administrative_redress].each do |type|
      resource.resource_type = type
      expect(resource).to be_valid
    end
  end

  it "rejects invalid resource_type" do
    action_resource = build(:action_resource)
    action_resource.resource_type = "invalid"
    expect(action_resource).not_to be_valid
    expect(action_resource.errors[:resource_type]).to be_present
  end

  it "accepts a valid URL" do
    resource.url = "https://example.com"
    expect(resource).to be_valid
  end

  it "accepts blank URL" do
    resource.url = ""
    expect(resource).to be_valid
  end

  describe "scopes" do
    before { Rails.application.load_seed }

    describe ".active" do
      it "returns only active resources" do
        active = ActionResource.active.first
        inactive = create(:action_resource, :inactive, institution: active.institution)

        expect(ActionResource.active).to include(active)
        expect(ActionResource.active).not_to include(inactive)
      end
    end

    describe ".verified" do
      it "returns only resources with last_verified_at" do
        verified = ActionResource.verified.first
        unverified = create(:action_resource, institution: verified.institution, last_verified_at: nil)

        expect(ActionResource.verified).to include(verified)
        expect(ActionResource.verified).not_to include(unverified)
      end
    end

    describe ".for_type" do
      it "filters by resource_type" do
        contact = ActionResource.for_type(:contact).first
        complaint = ActionResource.for_type(:complaint).first

        expect(ActionResource.for_type(:contact)).to include(contact)
        expect(ActionResource.for_type(:contact)).not_to include(complaint)
      end
    end
  end
end
