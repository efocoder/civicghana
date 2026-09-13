require "rails_helper"

RSpec.describe SourceChunk, type: :model do
  subject(:chunk) { build(:source_chunk) }

  it { is_expected.to belong_to(:source) }
  it { is_expected.to validate_presence_of(:content) }

  describe ".active_sources" do
    it "returns chunks from active sources only" do
      active_source = create(:source, active: true)
      inactive_source = create(:source, active: false, url: "https://inactive-#{SecureRandom.hex}.example.com")
      active_chunk = create(:source_chunk, source: active_source)
      inactive_chunk = create(:source_chunk, source: inactive_source)

      expect(SourceChunk.active_sources).to include(active_chunk)
      expect(SourceChunk.active_sources).not_to include(inactive_chunk)
    end
  end

  describe ".search_content" do
    it "finds chunks matching the query" do
      chunk = create(:source_chunk, content: "The Lands Commission shall issue the result within fourteen days.")

      results = SourceChunk.search_content("fourteen days")
      expect(results).to include(chunk)
    end

    it "does not return unmatched chunks" do
      chunk = create(:source_chunk, content: "CHRAJ handles administrative justice complaints.")

      results = SourceChunk.search_content("fourteen days payment")
      expect(results).not_to include(chunk)
    end
  end

  describe ".relevant_chunks" do
    it "handles generic duration questions without requiring a domain keyword" do
      service = create(:public_service)
      source = create(:source)
      create(:source_chunk, public_service: service, source: source,
        content: "The official service takes fourteen days after payment.", position: 1)

      results = SourceChunk.relevant_chunks(query: "How long does it take?", service: service)

      expect(results).not_to be_empty
    end
    it "combines active sources and search" do
      active = create(:source, active: true)
      inactive = create(:source, active: false, url: "https://inactive-#{SecureRandom.hex}.example.com")
      active_chunk = create(:source_chunk, source: active, content: "official search duration rule")
      inactive_chunk = create(:source_chunk, source: inactive, content: "official search duration rule")

      results = SourceChunk.relevant_chunks(query: "official search")
      expect(results).to include(active_chunk)
      expect(results).not_to include(inactive_chunk)
    end

    it "limits results" do
      source = create(:source, active: true)
      5.times { |i| create(:source_chunk, source: source, content: "search result #{i} for official query", position: i) }

      results = SourceChunk.relevant_chunks(query: "official query", limit: 3)
      expect(results.size).to eq(3)
    end
  end
end
