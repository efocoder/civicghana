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

      retrieval = Ai::Retrieval.call(query: question, service: service, limit: 5)
      return fallback("CivicRoute could not find relevant verified sources for your question.") if retrieval.chunks.empty?

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

      return fallback("CivicRoute could not verify that answer from the currently approved sources.") unless validation.valid

      Result.new(
        answer: answer,
        sources: retrieval.sources,
        valid: validation.valid
      )
    rescue Ai::Client::Error, Ai::Client::TimeoutError, Ai::Client::ProviderError
      fallback("AI explanation is temporarily unavailable. Your verified case assessment and recommended action remain available below.")
    end

    private

    attr_reader :question, :service

    def fallback(message)
      Result.new(answer: message, sources: [], valid: true)
    end
  end
end
