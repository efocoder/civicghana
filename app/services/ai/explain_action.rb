module Ai
  class ExplainAction
    Result = Data.define(:answer, :sources, :valid)

    def self.call(...) = new(...).call

    def initialize(action_recommendation:, service: nil)
      @action_recommendation = action_recommendation
      @service = service
    end

    def call
      system_prompt = Ai::PromptBuilder.system_prompt
      user_prompt = Ai::PromptBuilder.build_action_explanation_prompt(
        action_type: action_recommendation.action_type,
        explanation_code: action_recommendation.explanation_code,
        reasons: action_recommendation.reasons
      )

      retrieval = Ai::Retrieval.call(
        query: "#{action_recommendation.action_type} #{service&.name}",
        service: service,
        limit: 3
      )

      answer = Ai::Client.generate(
        system_prompt: system_prompt,
        user_prompt: user_prompt,
        context: retrieval.context_text
      )

      validation = Ai::ResponseValidator.call(
        response: answer,
        known_source_ids: retrieval.sources.map(&:id),
        known_urls: retrieval.sources.map(&:url).compact
      )

      return fallback("CivicRoute could not safely validate that explanation. Your verified recommendation remains available below.") unless validation.valid

      Result.new(
        answer: answer,
        sources: retrieval.sources,
        valid: validation.valid
      )
    rescue Ai::Client::Error, Ai::Client::TimeoutError, Ai::Client::ProviderError
      fallback("AI explanation is temporarily unavailable. Your verified case assessment and recommended action remain available below.")
    end

    private

    attr_reader :action_recommendation, :service

    def fallback(message)
      Result.new(answer: message, sources: [], valid: true)
    end
  end
end
