module Ai
  class Retrieval
    Result = Data.define(:chunks, :sources, :context_text)

    def self.call(...) = new(...).call

    def initialize(query:, service: nil, source: nil, limit: 5)
      @query = query
      @service = service
      @source = source
      @limit = limit
    end

    def call
      chunks = SourceChunk.relevant_chunks(query: query, service: service, source: source, limit: limit)
      sources = chunks.map(&:source).uniq
      # Directory and guided services may have verified Source records before
      # editorial SourceChunks are curated. Use their approved summaries as a
      # conservative fallback so every published service remains askable.
      if chunks.empty? && service.present? && query_related_to_service?
        sources = verified_service_sources
      end
      context_text = chunks.any? ? build_context(chunks) : build_source_summary_context(sources)

      Result.new(chunks: chunks, sources: sources, context_text: context_text)
    end

    private

    attr_reader :query, :service, :source, :limit

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

    def verified_service_sources
      relation = service.sources.merge(Source.verified)
      relation = relation.where(id: source.id) if source
      relation.order(:title).limit(limit).to_a
    end

    def query_related_to_service?
      terms = query.to_s.downcase.scan(/[[:alnum:]]+/).reject { |term| term.length < 3 }
      return true if terms.empty?

      searchable = [ service.name, service.description, *service.sources.merge(Source.verified).pluck(:title, :summary).flatten ]
        .compact.join(" ").downcase
      terms.any? { |term| searchable.include?(term) }
    end

    def build_source_summary_context(sources)
      sources.map do |record|
        parts = [ "Source: #{record.title}" ]
        parts << "Provision: #{record.section_label}" if record.section_label.present?
        parts << "Content: #{record.summary}"
        parts.join("\n")
      end.join("\n\n---\n\n")
    end
  end
end
