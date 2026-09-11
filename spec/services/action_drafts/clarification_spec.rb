require "rails_helper"

RSpec.describe ActionDrafts::Clarification do
  before { Rails.application.load_seed }

  let(:service) { PublicService.find_by!(slug: "official-consolidated-search") }
  let(:tracking_steps) { service.process_steps.where("sequence >= 4").order(:sequence) }

  let(:kase) do
    create(:case,
      public_service: service,
      application_completed_on: Date.new(2026, 7, 30),
      payment_date: Date.new(2026, 7, 27))
  end

  let(:observation) do
    obs = create(:case_observation, :portal, case: kase, observed_on: Date.new(2026, 8, 20))
    tracking_steps.each_with_index do |step, i|
      create(:case_milestone_observation,
        case_observation: obs,
        process_step: step,
        status: i == 0 ? "Pending" : "Not Completed")
    end
    obs
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
    draft = described_class.call(case_record: kase, observation: observation, rule_result: rule_result)

    expect(draft[:subject]).to include("Official / Consolidated Search")
  end

  it "includes application completion date" do
    draft = described_class.call(case_record: kase, observation: observation, rule_result: rule_result)

    expect(draft[:body]).to include("30 July 2026")
  end

  it "includes payment date when provided" do
    draft = described_class.call(case_record: kase, observation: observation, rule_result: rule_result)

    expect(draft[:body]).to include("27 July 2026")
  end

  it "includes portal observation summary" do
    draft = described_class.call(case_record: kase, observation: observation, rule_result: rule_result)

    expect(draft[:body]).to include("20 August 2026")
    expect(draft[:body]).to include("Quality Control and Coordinate Entry")
  end

  it "includes verified rule summary" do
    draft = described_class.call(case_record: kase, observation: observation, rule_result: rule_result)

    expect(draft[:body]).to include("14")
    expect(draft[:body]).to include("Land Act, 2020")
  end

  it "does not assert internal status" do
    draft = described_class.call(case_record: kase, observation: observation, rule_result: rule_result)

    expect(draft[:body]).not_to include("corrupt")
    expect(draft[:body]).not_to include("illegal")
    expect(draft[:body]).not_to include("negligent")
  end

  it "handles nil payment date" do
    kase.payment_date = nil
    draft = described_class.call(case_record: kase, observation: observation, rule_result: rule_result)

    expect(draft[:body]).not_to include("Payment date:")
  end

  it "handles nil portal_created_on" do
    kase.portal_created_on = nil
    draft = described_class.call(case_record: kase, observation: observation, rule_result: rule_result)

    expect(draft[:body]).not_to include("Portal Date Created:")
  end

  it "handles nil observation" do
    draft = described_class.call(case_record: kase, observation: nil, rule_result: rule_result)

    expect(draft[:body]).not_to include("portal was last observed")
  end
end
