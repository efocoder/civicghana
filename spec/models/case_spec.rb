require "rails_helper"

RSpec.describe Case, type: :model do
  subject(:kase) { build(:case) }

  it { is_expected.to belong_to(:public_service) }
  it { is_expected.to have_many(:case_observations).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:region) }
  it { is_expected.to validate_presence_of(:application_completed_on) }

  it "rejects a future application_completed_on" do
    kase.application_completed_on = Date.current + 1.day

    expect(kase).not_to be_valid
    expect(kase.errors[:application_completed_on]).to include("cannot be in the future")
  end

  it "accepts today as application_completed_on" do
    kase.application_completed_on = Date.current
    expect(kase).to be_valid
  end

  it "accepts a past application_completed_on" do
    kase.application_completed_on = Date.current - 30.days
    expect(kase).to be_valid
  end

  it "accepts nil payment_date" do
    kase.payment_date = nil
    expect(kase).to be_valid
  end

  it "rejects a future payment_date" do
    kase.payment_date = Date.current + 1.day

    expect(kase).not_to be_valid
    expect(kase.errors[:payment_date]).to include("cannot be in the future")
  end

  it "accepts nil portal_created_on" do
    kase.portal_created_on = nil
    expect(kase).to be_valid
  end

  it "rejects a future portal_created_on" do
    kase.portal_created_on = Date.current + 1.day

    expect(kase).not_to be_valid
    expect(kase.errors[:portal_created_on]).to include("cannot be in the future")
  end
end
