module Ai
  class Retrieval
    Result = Data.define(:chunks, :sources, :context_text)

    def self.call(...) = new(...).call

    def initialize(query:, service: nil, limit: 5)
      @query = query
      @service = service
      @limit = limit
    end

    def call
      chunks = SourceChunk.relevant_chunks(query: query, service: service, limit: limit)
      sources = chunks.map(&:source).uniq
      context_text = build_context(chunks)

      Result.new(chunks: chunks, sources: sources, context_text: context_text)
    end

    private

    attr_reader :query, :service, :limit

    def build_context(chunks)
      chunks.map do |chunk|
        parts = []
        parts << "Source: #{chunk.source.title}"
        parts << "Section: #{chunk.section_label}" if chunk.section_label.present?
        parts << "Provision: #{chunk.provision}" if chunk.provision.present?
        parts << "Content: #{chunk.content}"
        parts.join("\n")
      end.join("\n\n---\n\n")
    end
  end
end
