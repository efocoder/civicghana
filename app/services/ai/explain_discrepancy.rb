module Ai
  class ExplainDiscrepancy
    Result = Data.define(:answer, :sources, :valid)

    def self.call(...) = new(...).call

    def initialize(case_record:, evidence_comparison:)
      @case_record = case_record
      @evidence_comparison = evidence_comparison
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
      answer = Ai::Client.generate(
        system_prompt: Ai::PromptBuilder.system_prompt,
        user_prompt: "Explain this evidence comparison in plain language. Do not change the classification or claim which source is correct. Cite the verified source.",
        context: "#{context}\n\n#{retrieval.context_text}"
      )
      validation = Ai::ResponseValidator.call(
        response: answer,
        known_source_ids: retrieval.sources.map(&:id),
        known_urls: retrieval.sources.map(&:url).compact
      )
      return fallback("CivicRoute could not safely validate that explanation. The evidence classification remains unchanged.") unless validation.valid

      Result.new(answer: answer, sources: retrieval.sources, valid: true)
    rescue Ai::Client::Error, Ai::Client::TimeoutError, Ai::Client::ProviderError
      fallback("AI explanation is temporarily unavailable. The verified evidence classification remains available below.")
    end

    private

    attr_reader :case_record, :evidence_comparison

    def fallback(message)
      Result.new(answer: message, sources: [], valid: true)
    end
  end
end
