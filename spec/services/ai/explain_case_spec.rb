require "rails_helper"

RSpec.describe Ai::ExplainCase do
  before { Rails.application.load_seed }

  let(:service) { PublicService.find_by!(slug: "official-consolidated-search") }
  let(:kase) do
    create(:case,
      public_service: service,
      application_completed_on: Date.new(2026, 7, 30),
      payment_date: Date.new(2026, 7, 27))
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

  let(:evidence_comparison) do
    EvidenceAssessment::Compare::Result.new(
      status: :possible_stale_public_status,
      portal_observation: nil,
      comparison_observation: nil,
      explanation_code: :portal_unchanged_after_later_update,
      portal_changed: false,
      supporting_evidence: []
    )
  end

  let(:action_recommendation) do
    ActionRecommendation::Evaluate::Result.new(
      action_type: :clarification,
      explanation_code: :timeframe_exceeded_no_followup,
      reasons: [ "The verified published timeframe has elapsed." ],
      action_resource: nil,
      secondary_actions: []
    )
  end

  describe ".call" do
    it "returns AI explanation with sources" do
      allow(Ai::Client).to receive(:generate).and_return(
        Ai::Response.new(content: "Your case is 31 days overdue.", provider: "mimo", model: "test",
          input_tokens: 1, output_tokens: 1, raw_request_id: "test")
      )

      result = described_class.call(
        case_record: kase,
        rule_result: rule_result,
        evidence_comparison: evidence_comparison,
        action_recommendation: action_recommendation
      )

      expect(result.answer).to eq("Your case is 31 days overdue.")
      expect(result.valid).to be true
    end

    it "returns fallback when provider fails" do
      allow(Ai::Client).to receive(:generate).and_raise(Ai::Client::TimeoutError.new("timeout"))

      result = described_class.call(
        case_record: kase,
        rule_result: rule_result,
        evidence_comparison: evidence_comparison,
        action_recommendation: action_recommendation
      )

      expect(result.answer).to include("temporarily unavailable")
    end
  end
end
