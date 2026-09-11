require "rails_helper"

RSpec.describe ActionDrafts::Complaint do
  before { Rails.application.load_seed }

  let(:service) { PublicService.find_by!(slug: "official-consolidated-search") }
  let(:tracking_steps) { service.process_steps.where("sequence >= 4").order(:sequence) }

  let(:kase) do
    create(:case,
      public_service: service,
      application_completed_on: Date.new(2026, 7, 30),
      payment_date: Date.new(2026, 7, 27))
  end

  let(:observations) do
    obs = create(:case_observation, :portal, case: kase, observed_on: Date.new(2026, 8, 20))
    tracking_steps.each_with_index do |step, i|
      create(:case_milestone_observation,
        case_observation: obs,
        process_step: step,
        status: i == 0 ? "Pending" : "Not Completed")
    end
    kase.case_observations.order(:observed_on)
  end

  let(:rule_result) do
    source = Source.find_by!(title: "Land Act, 2020 (Act 1036)")
    rule = ServiceRule.find_by!(public_service: service, rule_type: :expected_duration_days)
    CaseAssessment::Evaluate::RuleResult.new(
      assessment_state: :timeframe_exceeded,
      published_days: 14,
      deadline: Date.new(2026, 8, 10),
      assessment_date: Date.new(2026, 9, 10),
      days_remaining: -31,
      days_beyond: 31,
      rule_anchor_date: Date.new(2026, 7, 27),
      rule_anchor_event: "payment",
      service_rule: rule,
      source: source
    )
  end

  it "generates subject with service name" do
    draft = described_class.call(
      case_record: kase, observations: observations,
      rule_result: rule_result, prior_actions: []
    )

    expect(draft[:subject]).to include("Official / Consolidated Search")
  end

  it "contains factual chronology" do
    draft = described_class.call(
      case_record: kase, observations: observations,
      rule_result: rule_result, prior_actions: []
    )

    expect(draft[:body]).to include("30 July 2026")
    expect(draft[:body]).to include("20 August 2026")
  end

  it "includes prior follow-up when present" do
    action = create(:case_action, :clarification, :taken, case: kase, taken_on: Date.new(2026, 9, 1))
    prior_actions = kase.case_actions.order(:created_at)

    draft = described_class.call(
      case_record: kase, observations: observations,
      rule_result: rule_result, prior_actions: prior_actions
    )

    expect(draft[:body]).to include("Follow-up already made")
  end

  it "does not state corruption or illegality" do
    draft = described_class.call(
      case_record: kase, observations: observations,
      rule_result: rule_result, prior_actions: []
    )

    expect(draft[:body]).not_to include("corrupt")
    expect(draft[:body]).not_to include("illegal")
    expect(draft[:body]).not_to include("negligent")
  end
end
