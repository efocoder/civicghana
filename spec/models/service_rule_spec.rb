require "rails_helper"

RSpec.describe ServiceRule, type: :model do
  subject(:rule) { build(:service_rule) }

  it { is_expected.to belong_to(:public_service) }
  it { is_expected.to belong_to(:source) }
  it { is_expected.to validate_presence_of(:effective_from) }
  it { is_expected.to validate_numericality_of(:value).is_greater_than_or_equal_to(0) }

  it "rejects a period that ends before it starts" do
    rule.effective_to = rule.effective_from - 1.day

    expect(rule).not_to be_valid
    expect(rule.errors[:effective_to]).to include("must be on or after the effective from date")
  end

  it "requires a source for every rule" do
    rule.source = nil

    expect(rule).not_to be_valid
    expect(rule.errors[:source]).to include("must exist")
  end
end
