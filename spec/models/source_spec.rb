require "rails_helper"

RSpec.describe Source, type: :model do
  subject(:source) { build(:source) }

  it { is_expected.to have_many(:service_rules).dependent(:restrict_with_error) }
  it { is_expected.to have_many(:process_steps).dependent(:restrict_with_error) }
  it { is_expected.to have_many(:action_paths).dependent(:restrict_with_error) }
  it { is_expected.to validate_presence_of(:publisher) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:url) }
  it { is_expected.to validate_presence_of(:summary) }
  it { is_expected.to validate_presence_of(:verified_at) }
  it { is_expected.to validate_presence_of(:content_hash) }
  it { is_expected.to validate_uniqueness_of(:url) }

  it "defines the expected authority_type enum values" do
    expect(Source.authority_types.keys).to contain_exactly(
      "legislation", "official_service", "regulator_guidance", "oversight_body"
    )
  end

  it "rejects an invalid authority_type" do
    source.authority_type = "unknown"
    expect(source).not_to be_valid
    expect(source.errors[:authority_type]).to be_present
  end

  it "rejects a content_hash that is not a 64-character hex string" do
    source.content_hash = "not-a-hash"
    expect(source).not_to be_valid
    expect(source.errors[:content_hash]).to be_present
  end

  it "accepts a valid SHA-256 content_hash" do
    source.content_hash = Digest::SHA256.hexdigest("test")
    expect(source).to be_valid
  end

  it "rejects an effective_to before effective_from" do
    source.effective_from = Date.new(2025, 1, 1)
    source.effective_to = Date.new(2024, 12, 31)

    expect(source).not_to be_valid
    expect(source.errors[:effective_to]).to include("must be on or after the effective from date")
  end

  it "restricts deletion when service_rules exist" do
    source.save!
    create(:service_rule, source: source)

    expect(source.destroy).to be_falsey
    expect(source.errors).to be_present
  end
end
