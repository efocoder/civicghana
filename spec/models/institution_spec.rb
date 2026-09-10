require "rails_helper"

RSpec.describe Institution, type: :model do
  subject(:institution) { build(:institution) }

  it { is_expected.to belong_to(:country) }
  it { is_expected.to have_many(:public_services).dependent(:restrict_with_error) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:official_url) }
  it { is_expected.to validate_presence_of(:description) }
  it { is_expected.to validate_uniqueness_of(:name).scoped_to(:country_id) }

  it "rejects an invalid URL" do
    institution.official_url = "not-a-url"

    expect(institution).not_to be_valid
    expect(institution.errors[:official_url]).to be_present
  end

  it "accepts an https URL" do
    institution.official_url = "https://example.gov.gh"
    expect(institution).to be_valid
  end
end
