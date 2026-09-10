require "rails_helper"

RSpec.describe PublicService, type: :model do
  subject(:service) { build(:public_service) }

  it { is_expected.to belong_to(:institution) }
  it { is_expected.to have_many(:process_steps).dependent(:restrict_with_error) }
  it { is_expected.to have_many(:service_rules).dependent(:restrict_with_error) }
  it { is_expected.to have_many(:action_paths).dependent(:restrict_with_error) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:slug) }
  it { is_expected.to validate_presence_of(:description) }
  it { is_expected.to validate_presence_of(:service_category) }
  it { is_expected.to validate_uniqueness_of(:name).scoped_to(:institution_id) }
  it { is_expected.to validate_uniqueness_of(:slug).ignoring_case_sensitivity }

  it "rejects an invalid slug format" do
    service.slug = "Invalid Slug!"
    expect(service).not_to be_valid
  end

  it "accepts a valid slug" do
    service.slug = "valid-service-slug"
    expect(service).to be_valid
  end

  it "normalizes slug to lowercase" do
    service.slug = "OFFICIAL-SEARCH"
    service.valid?
    expect(service.slug).to eq("official-search")
  end
end
