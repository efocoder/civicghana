module Ai
  class Client
    class Error < StandardError; end
    class ConfigurationError < Error; end
    class TimeoutError < Error; end
    class ProviderError < Error; end

    def self.generate(system_prompt:, user_prompt:, context: nil)
      new.generate(system_prompt: system_prompt, user_prompt: user_prompt, context: context)
    end

    def generate(system_prompt:, user_prompt:, context: nil)
      messages = build_messages(system_prompt, user_prompt, context)

      response = with_retry { request(messages) }

      extract_content(response)
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
      raise TimeoutError, "AI service timed out: #{e.message}"
    rescue Faraday::TooManyRequestsError => e
      # A provider-side 429 is not retryable here. Retrying immediately can
      # amplify quota/rate-limit failures; surface the normal CivicRoute
      # provider-failure fallback instead.
      raise ProviderError, "AI provider rate limit: #{e.message}"
    rescue OpenAI::Error => e
      raise ProviderError, "AI provider error: #{e.message}"
    end

    private

    def request(messages)
      with_timeout do
        client.chat(parameters: {
          model: model_name,
          messages: messages,
          max_tokens: max_tokens,
          temperature: 0.3
        })
      end
    end

    def with_retry
      attempts = 0
      begin
        attempts += 1
        yield
      rescue Faraday::TimeoutError, Faraday::ConnectionFailed
        retry if attempts < 2
        raise
      end
    end

    def client
      @client ||= OpenAI::Client.new(
        access_token: api_key,
        request_timeout: timeout
      )
    end

    def build_messages(system_prompt, user_prompt, context)
      messages = [ { role: "system", content: system_prompt } ]

      if context.present?
        messages << { role: "system", content: "Verified CivicRoute context:\n\n#{context}" }
      end

      messages << { role: "user", content: user_prompt }
      messages
    end

    def extract_content(response)
      content = response.dig("choices", 0, "message", "content")&.strip
      raise ProviderError, "AI provider returned an empty response" if content.blank?

      content
    end

    def with_timeout(&block)
      Timeout.timeout(timeout, &block)
    end

    def api_key
      environment_key = ENV.fetch("OPENAI_API_KEY")
      environment_key.presence || Rails.application.credentials.dig(:openai, :api_key).presence ||
        raise(ConfigurationError, "AI provider is not configured")
    rescue KeyError
      Rails.application.credentials.dig(:openai, :api_key).presence ||
        raise(ConfigurationError, "AI provider is not configured")
    end

    def model_name
      ENV.fetch("OPENAI_MODEL", "gpt-4o-mini")
    end

    def max_tokens
      ENV.fetch("AI_MAX_TOKENS", "1000").to_i
    end

    def timeout
      ENV.fetch("AI_TIMEOUT", "30").to_i
    end
  end
end
