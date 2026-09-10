require "rails_helper"

RSpec.describe Country, type: :model do
  subject(:country) { build(:country) }

  it { is_expected.to have_many(:institutions).dependent(:restrict_with_error) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:code) }
  it { is_expected.to validate_uniqueness_of(:code).ignoring_case_sensitivity }
  it { is_expected.to validate_length_of(:code).is_equal_to(2) }

  it "normalizes code to uppercase" do
    country.code = "gh"
    country.valid?
    expect(country.code).to eq("GH")
  end

  it "rejects a duplicate code" do
    create(:country, code: "ZZ")
    duplicate = build(:country, code: "ZZ")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:code]).to include("has already been taken")
  end
end
