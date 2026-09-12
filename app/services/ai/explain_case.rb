module Ai
  class ExplainCase
    Result = Data.define(:answer, :sources, :valid, :provider_failed)

    def self.call(...) = new(...).call

    def initialize(case_record:, rule_result:, evidence_comparison:, action_recommendation:, provider: Ai::ProviderRegistry.default_name)
      @case_record = case_record
      @rule_result = rule_result
      @evidence_comparison = evidence_comparison
      @action_recommendation = action_recommendation
      @provider = provider
    end

    def call
      case_facts = Ai::CaseContextBuilder.call(
        case_record: case_record,
        rule_result: rule_result,
        evidence_comparison: evidence_comparison,
        action_recommendation: action_recommendation
      )

      retrieval = Ai::Retrieval.call(
        query: "#{case_record.public_service.name} official search duration",
        service: case_record.public_service,
        limit: 3
      )
      return fallback("CivicRoute could not verify an answer from the currently approved sources.") if retrieval.chunks.empty?

      system_prompt = Ai::PromptBuilder.system_prompt
      user_prompt = Ai::PromptBuilder.build_case_explanation_prompt(case_facts: case_facts)

      response = Ai::Client.generate(
        provider: provider,
        task: :case_explanation,
        system_prompt: system_prompt,
        user_prompt: user_prompt,
        context: retrieval.context_text
      )

      known_dates = [
        case_record.application_completed_on,
        case_record.payment_date,
        case_record.portal_created_on,
        rule_result&.deadline,
        rule_result&.assessment_date,
        rule_result&.rule_anchor_date
      ].compact.map { |d| d.strftime("%-d %B %Y") }

      validation = Ai::ResponseValidator.call(
        response: response.content,
        known_dates: known_dates,
        known_source_ids: retrieval.sources.map(&:id),
        known_urls: retrieval.sources.map(&:url).compact
      )

      return fallback("CivicRoute could not safely validate that explanation. Your verified assessment remains available below.") unless validation.valid

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

    attr_reader :case_record, :rule_result, :evidence_comparison, :action_recommendation, :provider

    def fallback(message, provider_failed: false)
      Result.new(answer: message, sources: [], valid: true, provider_failed: provider_failed)
    end
  end
end
