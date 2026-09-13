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

    it "falls back to verified service source summaries when chunks are not curated yet" do
      service = create(:public_service)
      source = create(:source, summary: "This service is provided by the public institution.")
      create(:service_source, public_service: service, source: source, purpose: "Official service information")

      result = described_class.call(query: "What does this service do?", service: service)

      expect(result.chunks).to be_empty
      expect(result.sources).to contain_exactly(source)
      expect(result.context_text).to include(source.title, source.summary)
    end

    it "does not use unrelated source summaries as context" do
      service = create(:public_service)
      source = create(:source)
      create(:service_source, public_service: service, source: source, purpose: "Official service information")

      result = described_class.call(query: "unrelated topic xyz123 no match", service: service)

      expect(result.sources).to be_empty
      expect(result.context_text).to be_blank
    end
  end
end
