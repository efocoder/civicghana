require "rails_helper"

RSpec.describe Ai::Retrieval do
  before { Rails.application.load_seed }

  describe ".call" do
    it "returns relevant chunks and sources" do
      result = described_class.call(query: "fourteen days official search")

      expect(result.chunks).to be_present
      expect(result.sources).to be_present
      expect(result.context_text).to be_present
    end

    it "returns empty when no matches" do
      result = described_class.call(query: "completely unrelated topic xyz123")

      expect(result.chunks).to be_empty
      expect(result.sources).to be_empty
    end

    it "includes source metadata in context" do
      result = described_class.call(query: "fourteen days official search")

      expect(result.context_text).to include("Source:")
      expect(result.context_text).to include("Content:")
    end
  end
end
