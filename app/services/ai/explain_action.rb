module Ai
  class ExplainAction
    Result = Data.define(:answer, :sources, :valid, :provider_failed)

    def self.call(...) = new(...).call

    def initialize(action_recommendation:, service: nil, provider: Ai::ProviderRegistry.default_name)
      @action_recommendation = action_recommendation
      @service = service
      @provider = provider
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
      return fallback("CivicRoute could not verify an answer from the currently approved sources.") if retrieval.sources.empty?

      response = Ai::Client.generate(
        provider: provider,
        task: :action_explanation,
        system_prompt: system_prompt,
        user_prompt: user_prompt,
        context: retrieval.context_text
      )

      validation = Ai::ResponseValidator.call(
        response: response.content,
        known_source_ids: retrieval.sources.map(&:id),
        known_urls: retrieval.sources.map(&:url).compact
      )

      return fallback("CivicRoute could not safely validate that explanation. Your verified recommendation remains available below.") unless validation.valid

      Result.new(
        answer: response.content,
        sources: retrieval.sources,
        valid: validation.valid,
        provider_failed: false
      )
    rescue Ai::Client::ConfigurationError
      fallback("CivicRoute Assistant is currently unavailable. Your verified service information and case assessment are still available.", provider_failed: true)
    rescue Ai::Client::Error
      fallback("#{Ai::ProviderRegistry.fetch(provider).display_name} is temporarily unavailable. Your verified case assessment and recommended action remain available below.", provider_failed: true)
    end

    private

    attr_reader :action_recommendation, :service, :provider

    def fallback(message, provider_failed: false)
      Result.new(answer: message, sources: [], valid: true, provider_failed: provider_failed)
    end
  end
end
