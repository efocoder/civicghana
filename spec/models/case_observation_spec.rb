require "rails_helper"

RSpec.describe CaseObservation, type: :model do
  subject(:observation) { build(:case_observation) }

  it { is_expected.to belong_to(:case) }
  it { is_expected.to belong_to(:reported_process_step).optional }
  it { is_expected.to have_many(:case_milestone_observations).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:observed_on) }
  it { is_expected.to validate_length_of(:summary).is_at_most(1000) }

  it "defines the expected observation_type enum values" do
    expect(CaseObservation.observation_types.keys).to contain_exactly(
      "portal", "phone", "in_person", "email", "letter", "sms", "other"
    )
  end

  it "defines the expected progress_claim enum values" do
    expect(CaseObservation.progress_claims.keys).to contain_exactly(
      "unspecified", "public_milestone", "near_completion", "completed", "other_claim"
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

  context "when portal" do
    subject(:observation) { build(:case_observation, :portal) }

    it "does not require progress_claim" do
      observation.progress_claim = nil
      expect(observation).to be_valid
    end

    it "does not require summary" do
      observation.summary = nil
      expect(observation).to be_valid
    end
  end

  context "when non-portal" do
    subject(:observation) { build(:case_observation, :phone) }

    it "requires progress_claim" do
      observation.progress_claim = nil
      expect(observation).not_to be_valid
      expect(observation.errors[:progress_claim]).to include("is required for non-portal evidence")
    end

    it "requires reported_process_step when progress_claim is public_milestone" do
      observation.progress_claim = :public_milestone
      observation.reported_process_step = nil

      expect(observation).not_to be_valid
      expect(observation.errors[:reported_process_step_id]).to include("is required when progress claim is a public milestone")
    end
  end
end
