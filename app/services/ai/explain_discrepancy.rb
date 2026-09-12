module Ai
  class ExplainDiscrepancy
    Result = Data.define(:answer, :sources, :valid, :provider_failed)

    def self.call(...) = new(...).call

    def initialize(case_record:, evidence_comparison:, provider: Ai::ProviderRegistry.default_name)
      @case_record = case_record
      @evidence_comparison = evidence_comparison
      @provider = provider
    end

    def call
      retrieval = Ai::Retrieval.call(
        query: "portal status",
        service: case_record.public_service,
        limit: 3
      )
      return fallback("CivicRoute could not find relevant verified sources for this explanation.") if retrieval.chunks.empty?

      context = [
        "Service: #{case_record.public_service.name}",
        "Evidence classification: #{evidence_comparison.status}",
        "CivicRoute cannot determine the institution's internal status."
      ].join("\n")
      response = Ai::Client.generate(
        provider: provider,
        task: :discrepancy_explanation,
        system_prompt: Ai::PromptBuilder.system_prompt,
        user_prompt: "Explain this evidence comparison in plain language. Do not change the classification or claim which source is correct. Cite the verified source.",
        context: "#{context}\n\n#{retrieval.context_text}"
      )
      validation = Ai::ResponseValidator.call(
        response: response.content,
        known_source_ids: retrieval.sources.map(&:id),
        known_urls: retrieval.sources.map(&:url).compact
      )
      return fallback("CivicRoute could not safely validate that explanation. The evidence classification remains unchanged.") unless validation.valid

      Result.new(answer: response.content, sources: retrieval.sources, valid: true, provider_failed: false)
    rescue Ai::Client::ConfigurationError
      fallback("CivicRoute Assistant is currently unavailable. Your verified service information and case assessment are still available.", provider_failed: true)
    rescue Ai::Client::Error
      fallback("#{Ai::ProviderRegistry.fetch(provider).display_name} is temporarily unavailable. The verified evidence classification remains available below.", provider_failed: true)
    end

    private

    attr_reader :case_record, :evidence_comparison, :provider

    def fallback(message, provider_failed: false)
      Result.new(answer: message, sources: [], valid: true, provider_failed: provider_failed)
    end
  end
end
