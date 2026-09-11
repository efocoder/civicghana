require "rails_helper"

RSpec.describe ActionRecommendation::Evaluate do
  before { Rails.application.load_seed }

  let(:service) { PublicService.find_by!(slug: "official-consolidated-search") }
  let(:tracking_steps) { service.process_steps.where("sequence >= 4").order(:sequence) }
  let(:institution) { service.institution }

  let(:kase) do
    create(:case,
      public_service: service,
      application_completed_on: Date.new(2026, 7, 30),
      payment_date: Date.new(2026, 7, 27))
  end

  def create_portal_snapshot(date, statuses)
    observation = create(:case_observation, :portal, case: kase, observed_on: date)
    tracking_steps.each_with_index do |step, i|
      create(:case_milestone_observation,
        case_observation: observation,
        process_step: step,
        status: statuses[i] || "Not Completed")
    end
    observation
  end

  def build_rule_result(state)
    source = Source.find_by!(title: "Land Act, 2020 (Act 1036)")
    rule = ServiceRule.find_by!(public_service: service, rule_type: :expected_duration_days)
    CaseAssessment::Evaluate::RuleResult.new(
      assessment_state: state,
      published_days: 14,
      deadline: Date.new(2026, 8, 10),
      assessment_date: Date.new(2026, 9, 10),
      days_remaining: state == :within_timeframe ? 5 : -31,
      days_beyond: state == :timeframe_exceeded ? 31 : 0,
      rule_anchor_date: Date.new(2026, 7, 27),
      rule_anchor_event: "payment",
      service_rule: rule,
      source: source
    )
  end

  def build_evidence_result(status)
    EvidenceAssessment::Compare::Result.new(
      status: status,
      portal_observation: nil,
      comparison_observation: nil,
      explanation_code: :test,
      portal_changed: nil,
      supporting_evidence: []
    )
  end

  describe "Rule 1 — within timeframe" do
    it "returns monitor when within timeframe" do
      rule = build_rule_result(:within_timeframe)
      evidence = build_evidence_result(:no_comparison)

      result = described_class.call(case_record: kase, rule_result: rule, evidence_comparison: evidence)

      expect(result.action_type).to eq(:monitor)
      expect(result.explanation_code).to eq(:within_published_timeframe)
    end
  end

  describe "Rule 2 — due today" do
    it "returns monitor when due today" do
      rule = build_rule_result(:due_today)
      evidence = build_evidence_result(:no_comparison)

      result = described_class.call(case_record: kase, rule_result: rule, evidence_comparison: evidence)

      expect(result.action_type).to eq(:monitor)
      expect(result.explanation_code).to eq(:within_published_timeframe)
    end
  end

  describe "Rule 3 — timeframe exceeded, no follow-up" do
    it "returns request_clarification" do
      rule = build_rule_result(:timeframe_exceeded)
      evidence = build_evidence_result(:no_comparison)

      result = described_class.call(case_record: kase, rule_result: rule, evidence_comparison: evidence)

      expect(result.action_type).to eq(:clarification)
      expect(result.explanation_code).to eq(:timeframe_exceeded_no_followup)
      expect(result.action_resource).to be_present
      expect(result.action_resource.resource_type).to eq("contact")
    end
  end

  describe "Rule 4 — possible discrepancy, no follow-up" do
    it "returns request_clarification" do
      rule = build_rule_result(:timeframe_exceeded)
      evidence = build_evidence_result(:possible_discrepancy)

      result = described_class.call(case_record: kase, rule_result: rule, evidence_comparison: evidence)

      expect(result.action_type).to eq(:clarification)
      expect(result.explanation_code).to eq(:evidence_discrepancy_no_followup)
    end
  end

  describe "Rule 5 — possible stale public status" do
    it "returns clarification when no prior follow-up" do
      rule = build_rule_result(:timeframe_exceeded)
      evidence = build_evidence_result(:possible_stale_public_status)

      result = described_class.call(case_record: kase, rule_result: rule, evidence_comparison: evidence)

      expect(result.action_type).to eq(:clarification)
      expect(result.explanation_code).to eq(:stale_status_after_followup)
    end

    it "returns complaint when clarification already taken and unresolved" do
      rule = build_rule_result(:timeframe_exceeded)
      evidence = build_evidence_result(:possible_stale_public_status)
      create(:case_action, :clarification, case: kase, status: :taken, taken_on: Date.current, outcome: :outcome_unresolved)

      result = described_class.call(case_record: kase, rule_result: rule, evidence_comparison: evidence)

      expect(result.action_type).to eq(:complaint)
      expect(result.explanation_code).to eq(:clarification_unresolved)
    end
  end

  describe "Rule 6 — clarification sent, awaiting response" do
    it "returns monitor with clarification_already_taken" do
      rule = build_rule_result(:timeframe_exceeded)
      evidence = build_evidence_result(:no_comparison)
      create(:case_action, :clarification, :taken, case: kase)

      result = described_class.call(case_record: kase, rule_result: rule, evidence_comparison: evidence)

      expect(result.action_type).to eq(:monitor)
      expect(result.explanation_code).to eq(:clarification_already_taken)
    end
  end

  describe "Rule 7 — clarification unresolved" do
    it "returns formal complaint" do
      rule = build_rule_result(:timeframe_exceeded)
      evidence = build_evidence_result(:no_comparison)
      create(:case_action, :clarification, case: kase, status: :taken, taken_on: Date.current, outcome: :outcome_unresolved)

      result = described_class.call(case_record: kase, rule_result: rule, evidence_comparison: evidence)

      expect(result.action_type).to eq(:complaint)
      expect(result.explanation_code).to eq(:clarification_unresolved)
      expect(result.action_resource).to be_present
      expect(result.action_resource.resource_type).to eq("complaint")
    end
  end

  describe "secondary actions" do
    it "includes RTI as a secondary option when specifically requested" do
      rule = build_rule_result(:timeframe_exceeded)
      evidence = build_evidence_result(:no_comparison)

      result = described_class.call(case_record: kase, rule_result: rule, evidence_comparison: evidence, information_need: :specific_information)

      rti = result.secondary_actions.find { |a| a.action_type == :rti }
      expect(rti).to be_present
      expect(rti.explanation_code).to eq(:specific_information_requested)
    end

    it "includes CHRAJ when prior institutional contact exists" do
      rule = build_rule_result(:timeframe_exceeded)
      evidence = build_evidence_result(:no_comparison)
      create(:case_action, :clarification, :taken, case: kase, outcome: :outcome_unresolved)

      result = described_class.call(case_record: kase, rule_result: rule, evidence_comparison: evidence)

      chraj = result.secondary_actions.find { |a| a.action_type == :chraj }
      expect(chraj).to be_present
      expect(chraj.explanation_code).to eq(:institutional_resolution_unsuccessful)
    end

    it "does not include CHRAJ when no prior contact" do
      rule = build_rule_result(:within_timeframe)
      evidence = build_evidence_result(:no_comparison)

      result = described_class.call(case_record: kase, rule_result: rule, evidence_comparison: evidence)

      chraj = result.secondary_actions.find { |a| a.action_type == :chraj }
      expect(chraj).to be_nil
    end
  end
end
