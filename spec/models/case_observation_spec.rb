require "rails_helper"

RSpec.describe CaseObservation, type: :model do
  subject(:observation) { build(:case_observation) }

  it { is_expected.to belong_to(:case) }
  it { is_expected.to have_many(:case_milestone_observations).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:observed_on) }

  it "defines the expected observation_type enum values" do
    expect(CaseObservation.observation_types.keys).to contain_exactly(
      "portal", "phone", "in_person", "email", "letter", "other"
    )
  end

  it "rejects an invalid observation_type" do
    observation.observation_type = "unknown"
    expect(observation).not_to be_valid
    expect(observation.errors[:observation_type]).to be_present
  end

  it "rejects a future observed date" do
    observation.observed_on = Date.current + 1.day

    expect(observation).not_to be_valid
    expect(observation.errors[:observed_on]).to include("cannot be in the future")
  end

  it "rejects an observed date before application completion" do
    observation.case.application_completed_on = Date.current - 10.days
    observation.observed_on = Date.current - 20.days

    expect(observation).not_to be_valid
    expect(observation.errors[:observed_on]).to include("cannot be earlier than the application completion date")
  end

  it "accepts a blank overall_status" do
    observation.overall_status = nil
    expect(observation).to be_valid
  end

  it "accepts an observed date on the application completion date" do
    observation.case.application_completed_on = Date.current - 5.days
    observation.observed_on = Date.current - 5.days

    expect(observation).to be_valid
  end
end
