require "rails_helper"

RSpec.describe ProcessStep, type: :model do
  subject(:step) { build(:process_step) }

  it { is_expected.to belong_to(:public_service) }
  it { is_expected.to belong_to(:source).optional }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:description) }
  it { is_expected.to validate_numericality_of(:sequence).only_integer.is_greater_than(0) }

  it "rejects a duplicate sequence within the same service" do
    create(:process_step, public_service: step.public_service, sequence: 1)
    duplicate = build(:process_step, public_service: step.public_service, sequence: 1)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:sequence]).to include("has already been taken")
  end

  it "allows the same sequence across different services" do
    create(:process_step, sequence: 1)
    other = build(:process_step, sequence: 1)

    expect(other).to be_valid
  end
end
