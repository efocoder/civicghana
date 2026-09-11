require "rails_helper"

RSpec.describe CaseAction, type: :model do
  subject(:action) { build(:case_action) }

  it { is_expected.to belong_to(:case) }
  it { is_expected.to belong_to(:action_resource).optional }
  it { is_expected.to validate_presence_of(:recommended_on) }

  it "rejects a future taken_on" do
    action.taken_on = Date.current + 1.day

    expect(action).not_to be_valid
    expect(action.errors[:taken_on]).to include("cannot be in the future")
  end

  it "accepts today as taken_on" do
    action.taken_on = Date.current
    action.status = :taken
    expect(action).to be_valid
  end

  it "accepts nil taken_on" do
    action.taken_on = nil
    expect(action).to be_valid
  end

  it "accepts valid action_type values" do
    %w[monitor clarification complaint rti chraj].each do |type|
      action.action_type = type
      expect(action).to be_valid
    end
  end

  it "rejects invalid action_type" do
    action.action_type = "invalid"
    expect(action).not_to be_valid
    expect(action.errors[:action_type]).to be_present
  end

  it "accepts valid status values" do
    %w[recommended prepared taken responded resolved unresolved cancelled].each do |status|
      action.status = status
      expect(action).to be_valid
    end
  end

  it "accepts valid outcome values" do
    %w[awaiting_response received_response].each do |outcome|
      action.outcome = outcome
      expect(action).to be_valid
    end
  end

  it "accepts nil outcome" do
    action.outcome = nil
    expect(action).to be_valid
  end

  describe "scopes" do
    before { Rails.application.load_seed }

    let(:kase) { create(:case, public_service: PublicService.find_by!(slug: "official-consolidated-search")) }

    describe ".active" do
      it "excludes cancelled and resolved actions" do
        active = create(:case_action, :clarification, case: kase, status: :taken)
        cancelled = create(:case_action, :clarification, case: kase, status: :cancelled)
        resolved = create(:case_action, :clarification, case: kase, status: :resolved, outcome: :outcome_resolved, taken_on: Date.current)

        expect(CaseAction.active).to include(active)
        expect(CaseAction.active).not_to include(cancelled)
        expect(CaseAction.active).not_to include(resolved)
      end
    end

    describe ".for_type" do
      it "filters by action_type" do
        clarification = create(:case_action, :clarification, case: kase)
        complaint = create(:case_action, :complaint, case: kase)

        expect(CaseAction.for_type(:clarification)).to include(clarification)
        expect(CaseAction.for_type(:clarification)).not_to include(complaint)
      end
    end
  end
end
