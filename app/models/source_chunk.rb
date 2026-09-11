class SourceChunk < ApplicationRecord
  belongs_to :source

  validates :content, presence: true

  scope :active_sources, -> { joins(:source).where(sources: { active: true }) }

  scope :search_content, ->(query) {
    where("content_tsv @@ plainto_tsquery('english', ?)", query)
  }

  scope :for_service, ->(service) {
    joins(:source).where(
      "sources.id IN (?) OR sources.authority_type IN (?)",
      Source.where(id: service.service_rules.select(:source_id))
        .or(Source.where(id: service.process_steps.select(:source_id)))
        .or(Source.where(id: service.action_paths.select(:source_id)))
        .select(:id),
      %w[legislation official_service]
    )
  }

  def self.relevant_chunks(query:, service: nil, limit: 5)
    chunks = active_sources.search_content(query)
    chunks = chunks.for_service(service) if service
    chunks.includes(:source).order(position: :asc).limit(limit)
  end
end
