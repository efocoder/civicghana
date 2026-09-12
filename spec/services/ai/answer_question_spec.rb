require "rails_helper"

RSpec.describe Ai::AnswerQuestion do
  before { Rails.application.load_seed }
  let(:service) { PublicService.find_by!(slug: "official-consolidated-search") }

  describe ".call" do
    it "returns fallback when question is blank" do
      result = described_class.call(question: "")

      expect(result.answer).to include("Please enter a question")
      expect(result.sources).to be_empty
    end

    it "returns fallback when question is too long" do
      result = described_class.call(question: "a" * 501)

      expect(result.answer).to include("too long")
    end

    it "returns grounded answer when sources found" do
      allow(Ai::Client).to receive(:generate).and_return("The search takes 14 days.")

      result = described_class.call(question: "official search fourteen days payment", service: service)

      expect(result.answer).to eq("The search takes 14 days.")
      expect(result.valid).to be true
    end

    it "returns fallback when no relevant sources found" do
      result = described_class.call(question: "unrelated topic xyz123 no match", service: service)

      expect(result.answer).to eq("CivicRoute could not verify an answer to that question from the currently approved sources.")
    end

    it "returns fallback when AI provider fails" do
      allow(Ai::Client).to receive(:generate).and_raise(Ai::Client::ProviderError.new("fail"))

      result = described_class.call(question: "official search fourteen days payment", service: service)

      expect(result.answer).to include("temporarily unavailable")
    end
  end
end
