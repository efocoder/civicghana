module Ai
  class AnswerQuestion
    Result = Data.define(:answer, :sources, :valid, :provider_failed)

    def self.call(...) = new(...).call

    def initialize(question:, service: nil, provider: Ai::ProviderRegistry.default_name, retrieval_query: nil, source: nil)
      @question = question.to_s.strip
      @service = service
      @provider = provider
      @retrieval_query = retrieval_query
      @source = source
    end

    def call
      return fallback("Please enter a question.") if question.blank?
      return fallback("Question is too long. Please keep it under 500 characters.") if question.length > 500
      return no_context_fallback unless service&.active?

      retrieval = Ai::Retrieval.call(query: retrieval_query || question, service: service, source: source, limit: 5)
      if retrieval.sources.empty?
        record_diagnostic(retrieval, provider_called: false, provider_success: false, validation: "not_run")
        return no_context_fallback
      end

      system_prompt = Ai::PromptBuilder.system_prompt
      user_prompt = Ai::PromptBuilder.build_qa_prompt(question: question)

      response = Ai::Client.generate(
        provider: provider,
        task: :service_question,
        system_prompt: system_prompt,
        user_prompt: user_prompt,
        context: retrieval.context_text
      )

      validation = Ai::ResponseValidator.call(
        response: response.content,
        known_source_ids: retrieval.sources.map(&:id),
        known_urls: retrieval.sources.map(&:url).compact
      )
      record_diagnostic(retrieval, provider_called: true, provider_success: true,
        validation: validation.valid ? "passed" : "failed")

      return fallback("CivicRoute could not verify that answer from the currently approved sources.") unless validation.valid

      Result.new(
        answer: response.content,
        sources: retrieval.sources,
        valid: validation.valid,
        provider_failed: false
      )
    rescue Ai::Client::ConfigurationError
      record_diagnostic(retrieval, provider_called: false, provider_success: false, validation: "not_run")
      fallback("CivicRoute Assistant is currently unavailable. Your verified service information and case assessment are still available.", provider_failed: true)
    rescue Ai::Client::DisabledError
      fallback("#{provider_display_name} is currently unavailable for CivicRoute.", provider_failed: true)
    rescue Ai::Client::TimeoutError
      fallback("#{provider_display_name} took too long to respond. Your verified CivicRoute information is still available.", provider_failed: true)
    rescue Ai::Client::Error
      record_diagnostic(retrieval, provider_called: true, provider_success: false, validation: "not_run")
      fallback("#{provider_display_name} is temporarily unavailable. Your verified CivicRoute information is still available.", provider_failed: true)
    end

    private

    attr_reader :question, :service, :provider, :retrieval_query, :source

    def provider_display_name
      Ai::ProviderRegistry.fetch(provider).display_name
    end

    def no_context_fallback
      fallback("CivicRoute could not verify an answer to that question from the currently approved sources.")
    end

    def record_diagnostic(retrieval, provider_called:, provider_success:, validation:)
      Ai::Diagnostics.record(
        service_id: service&.id,
        service_slug: service&.slug,
        chunk_ids: retrieval&.chunks&.map(&:id) || [],
        source_ids: retrieval&.sources&.map(&:id) || [],
        provider_called: provider_called,
        provider_success: provider_success,
        response_validation: validation
      )
    end

    def fallback(message, provider_failed: false)
      Result.new(answer: message, sources: [], valid: true, provider_failed: provider_failed)
    end
  end
end
