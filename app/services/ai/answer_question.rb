module Ai
  class AnswerQuestion
    Result = Data.define(:answer, :sources, :valid)

    def self.call(...) = new(...).call

    def initialize(question:, service: nil)
      @question = question.to_s.strip
      @service = service
    end

    def call
      return fallback("Please enter a question.") if question.blank?
      return fallback("Question is too long. Please keep it under 500 characters.") if question.length > 500
      return no_context_fallback unless service&.active?

      retrieval = Ai::Retrieval.call(query: question, service: service, limit: 5)
      if retrieval.chunks.empty?
        record_diagnostic(retrieval, provider_called: false, provider_success: false, validation: "not_run")
        return no_context_fallback
      end

      system_prompt = Ai::PromptBuilder.system_prompt
      user_prompt = Ai::PromptBuilder.build_qa_prompt(question: question)

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
      record_diagnostic(retrieval, provider_called: true, provider_success: true,
        validation: validation.valid ? "passed" : "failed")

      return fallback("CivicRoute could not verify that answer from the currently approved sources.") unless validation.valid

      Result.new(
        answer: answer,
        sources: retrieval.sources,
        valid: validation.valid
      )
    rescue Ai::Client::ConfigurationError
      record_diagnostic(retrieval, provider_called: false, provider_success: false, validation: "not_run")
      fallback("CivicRoute Assistant is not configured. The verified service guide and case assessment remain available.")
    rescue Ai::Client::Error
      record_diagnostic(retrieval, provider_called: true, provider_success: false, validation: "not_run")
      fallback("AI explanation is temporarily unavailable. Your verified CivicRoute information is still available.")
    end

    private

    attr_reader :question, :service

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

    def fallback(message)
      Result.new(answer: message, sources: [], valid: true)
    end
  end
end
