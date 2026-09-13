class SourceChunk < ApplicationRecord
  SEARCH_STOPWORDS = %w[about after again also an and are can could does for from how i in is it long many much of on or take tell that their this time to what when where which who why].freeze
  belongs_to :source
  belongs_to :public_service

  validates :content, presence: true

  scope :active_sources, -> { joins(:source).where(active: true, sources: { active: true }) }

  scope :search_content, ->(query) {
    where("content_tsv @@ to_tsquery('english', ?)", search_query(query))
  }

  scope :for_service, ->(service) { where(public_service: service) }

  def self.relevant_chunks(query:, service: nil, source: nil, limit: 5)
    ranked_query = search_query(query)
    chunks = active_sources
    chunks = chunks.where(source: source) if source
    meaningful_terms = query.to_s.downcase.scan(/[[:alnum:]]+/).uniq
      .reject { |term| term.length < 3 || SEARCH_STOPWORDS.include?(term) }
    # Generic questions such as “How long does it take?” contain no searchable
    # domain terms; for a service-scoped request, return its curated chunks in
    # editorial order rather than incorrectly claiming no verified context.
    if meaningful_terms.empty?
      scoped = service ? chunks.for_service(service) : chunks
      return scoped.includes(:source).order(:position).first(limit)
    end
    if ranked_query.present?
      metadata_terms = query.to_s.scan(/[[:alnum:]]+/).select { |term| term.length >= 3 }.uniq.first(20)
      text_matches = chunks.where("content_tsv @@ to_tsquery('english', ?)", ranked_query)
      metadata_matches = metadata_terms.reduce(chunks.none) do |matches, term|
        pattern = "%#{ActiveRecord::Base.sanitize_sql_like(term)}%"
        matches.or(chunks.where(
          "source_chunks.section_label ILIKE :pattern OR source_chunks.provision ILIKE :pattern OR sources.title ILIKE :pattern",
          pattern: pattern
        ))
      end
      chunks = text_matches.or(metadata_matches)
    else
      return []
    end
    chunks = chunks.for_service(service) if service
    candidates = chunks.includes(:source)
      .order(Arel.sql("ts_rank(content_tsv, to_tsquery('english', #{connection.quote(ranked_query)})) DESC"), :position)
      .to_a

    # Keep the database's stemming/ranking for paraphrases, but require at
    # least one meaningful query term to occur in the chunk. This prevents
    # false positives such as "completely" matching the source word
    # "Completed" while still allowing questions like "how long ... payment"
    # to find a source that says "within fourteen days after payment".
    terms = meaningful_terms
    return candidates.first(limit) if terms.empty?

    candidates.select do |chunk|
      searchable_text = [ chunk.content, chunk.section_label, chunk.provision, chunk.source&.title ].compact.join(" ").downcase
      terms.any? { |term| searchable_text.include?(term) }
    end.first(limit)
  end

  def self.search_query(query)
    query.to_s.scan(/[[:alnum:]]+/).select { |term| term.length >= 3 }.uniq.first(20).join(" | ")
  end
end
