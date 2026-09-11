require "rails_helper"

RSpec.describe Ai::ExplainAction do
  before { Rails.application.load_seed }

  let(:service) { PublicService.find_by!(slug: "official-consolidated-search") }

  let(:action_recommendation) do
    ActionRecommendation::Evaluate::Result.new(
      action_type: :clarification,
      explanation_code: :timeframe_exceeded_no_followup,
      reasons: [ "The verified published timeframe has elapsed.", "No written clarification has yet been recorded." ],
      action_resource: nil,
      secondary_actions: []
    )
  end

  describe ".call" do
    it "returns explanation with sources" do
      allow(Ai::Client).to receive(:generate).and_return("A follow-up is recommended because the timeframe has passed.")

      result = described_class.call(
        action_recommendation: action_recommendation,
        service: service
      )

      expect(result.answer).to include("follow-up")
      expect(result.valid).to be true
    end

    it "returns fallback when provider fails" do
      allow(Ai::Client).to receive(:generate).and_raise(Ai::Client::ProviderError.new("fail"))

      result = described_class.call(
        action_recommendation: action_recommendation,
        service: service
      )

      expect(result.answer).to include("temporarily unavailable")
    end
  end
end
