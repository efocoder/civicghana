require "rails_helper"

RSpec.describe ActionPath, type: :model do
  subject(:path) { build(:action_path) }

  it { is_expected.to belong_to(:public_service) }
  it { is_expected.to belong_to(:source) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:instructions) }
  it { is_expected.to validate_numericality_of(:sequence).only_integer.is_greater_than(0) }

  it "defines the expected action_type enum values" do
    expect(ActionPath.action_types.keys).to contain_exactly(
      "check", "verify", "agency_follow_up", "information_request", "external_escalation"
    )
  end

  it "rejects an invalid action_type" do
    path.action_type = "unknown"
    expect(path).not_to be_valid
    expect(path.errors[:action_type]).to be_present
  end

  it "rejects a duplicate sequence within the same service" do
    create(:action_path, public_service: path.public_service, sequence: 1)
    duplicate = build(:action_path, public_service: path.public_service, sequence: 1)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:sequence]).to include("has already been taken")
  end
end
