module Ai
  class RefineDraft
    Result = Data.define(:refined_text, :valid, :provider_failed)

    TONES = %w[clearer shorter more_formal polite plain_language].freeze

    def self.call(...) = new(...).call

    def initialize(draft_text:, tone: "clearer", provider: Ai::ProviderRegistry.default_name)
      @draft_text = draft_text.to_s.strip
      @tone = tone.to_s
      @provider = provider
    end

    def call
      return fallback("No draft text provided.") if draft_text.blank?
      return fallback("Invalid tone selected.") unless TONES.include?(tone)

      system_prompt = Ai::PromptBuilder.system_prompt
      user_prompt = Ai::PromptBuilder.build_draft_refinement_prompt(
        draft_text: draft_text,
        tone: tone_label
      )

      response = Ai::Client.generate(
        provider: provider,
        task: :draft_refinement,
        system_prompt: system_prompt,
        user_prompt: user_prompt
      )

      validation = Ai::ResponseValidator.call(
        response: response.content,
        known_dates: extract_dates(draft_text),
        known_urls: extract_urls(draft_text)
      )

      Result.new(
        refined_text: validation.valid ? response.content : draft_text,
        valid: validation.valid,
        provider_failed: false
      )
    rescue Ai::Client::ConfigurationError
      fallback("CivicRoute Assistant is currently unavailable. Your verified service information and case assessment are still available.", provider_failed: true)
    rescue Ai::Client::Error
      fallback("#{Ai::ProviderRegistry.fetch(provider).display_name} is temporarily unavailable. The original draft is shown below.", provider_failed: true)
    end

    private

    attr_reader :draft_text, :tone, :provider

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

    def fallback(message, provider_failed: false)
      Result.new(refined_text: message, valid: true, provider_failed: provider_failed)
    end
  end
end
