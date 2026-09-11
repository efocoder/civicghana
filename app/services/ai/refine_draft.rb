module Ai
  class RefineDraft
    Result = Data.define(:refined_text, :valid)

    TONES = %w[clearer shorter more_formal polite plain_language].freeze

    def self.call(...) = new(...).call

    def initialize(draft_text:, tone: "clearer")
      @draft_text = draft_text.to_s.strip
      @tone = tone.to_s
    end

    def call
      return fallback("No draft text provided.") if draft_text.blank?
      return fallback("Invalid tone selected.") unless TONES.include?(tone)

      system_prompt = Ai::PromptBuilder.system_prompt
      user_prompt = Ai::PromptBuilder.build_draft_refinement_prompt(
        draft_text: draft_text,
        tone: tone_label
      )

      refined = Ai::Client.generate(
        system_prompt: system_prompt,
        user_prompt: user_prompt
      )

      validation = Ai::ResponseValidator.call(
        response: refined,
        known_dates: extract_dates(draft_text),
        known_urls: extract_urls(draft_text)
      )

      Result.new(
        refined_text: validation.valid ? refined : draft_text,
        valid: validation.valid
      )
    rescue Ai::Client::Error, Ai::Client::TimeoutError, Ai::Client::ProviderError
      fallback("AI refinement is temporarily unavailable. The original draft is shown below.")
    end

    private

    attr_reader :draft_text, :tone

    def tone_label
      case tone
      when "clearer" then "clearer and easier to understand"
      when "shorter" then "shorter and more concise"
      when "more_formal" then "more formal and professional"
      when "polite" then "more polite and courteous"
      when "plain_language" then "simpler plain language with less legal jargon"
      else "clearer"
      end
    end

    def extract_dates(text)
      text.scan(/\b\d{1,2}\s+(?:January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{4}\b/i)
    end

    def extract_urls(text)
      text.scan(%r{https?://[^\s"')]+})
    end

    def fallback(message)
      Result.new(refined_text: message, valid: true)
    end
  end
end
