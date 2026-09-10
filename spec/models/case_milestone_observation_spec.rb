require "rails_helper"

RSpec.describe CaseMilestoneObservation, type: :model do
  subject(:milestone) { build(:case_milestone_observation) }

  it { is_expected.to belong_to(:case_observation) }
  it { is_expected.to belong_to(:process_step) }
  it { is_expected.to validate_presence_of(:status) }

  it "rejects a duplicate process step within the same snapshot" do
    milestone.save!
    duplicate = build(:case_milestone_observation,
      case_observation: milestone.case_observation,
      process_step: milestone.process_step)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:process_step_id]).to include("has already been taken")
  end

  it "allows the same process step across different snapshots" do
    create(:case_milestone_observation, process_step: milestone.process_step)
    other = build(:case_milestone_observation, process_step: milestone.process_step)

    expect(other).to be_valid
  end
end
