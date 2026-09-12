require "rails_helper"

RSpec.describe Ai::RefineDraft do
  describe ".call" do
    it "returns fallback when draft is blank" do
      result = described_class.call(draft_text: "", tone: "clearer")

      expect(result.refined_text).to include("No draft text")
    end

    it "returns fallback for invalid tone" do
      result = described_class.call(draft_text: "Some draft text", tone: "invalid")

      expect(result.refined_text).to include("Invalid tone")
    end

    it "returns refined text on success" do
      allow(Ai::Client).to receive(:generate).and_return(ai_response("Refined draft text here."))

      result = described_class.call(draft_text: "Original draft.", tone: "clearer")

      expect(result.refined_text).to eq("Refined draft text here.")
      expect(result.valid).to be true
    end

    it "falls back to original when validation fails" do
      allow(Ai::Client).to receive(:generate).and_return(ai_response("New deadline is 15 March 2026."))

      result = described_class.call(draft_text: "Original deadline 10 August 2026.", tone: "clearer")

      expect(result.refined_text).to eq("Original deadline 10 August 2026.")
      expect(result.valid).to be false
    end

    it "returns fallback when provider fails" do
      allow(Ai::Client).to receive(:generate).and_raise(Ai::Client::TimeoutError.new("timeout"))

      result = described_class.call(draft_text: "Some draft.", tone: "clearer")

      expect(result.refined_text).to include("temporarily unavailable")
    end

    it "accepts all valid tones" do
      allow(Ai::Client).to receive(:generate).and_return(ai_response("Refined."))

      %w[clearer shorter more_formal polite plain_language].each do |tone|
        result = described_class.call(draft_text: "Draft.", tone: tone)
        expect(result.refined_text).to eq("Refined.")
      end
    end
  end

  def ai_response(content)
    Ai::Response.new(content: content, provider: "mimo", model: "test",
      input_tokens: 1, output_tokens: 1, raw_request_id: "test")
  end
end
