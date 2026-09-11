module Ai
  class Client
    class Error < StandardError; end
    class TimeoutError < Error; end
    class ProviderError < Error; end

    def self.generate(system_prompt:, user_prompt:, context: nil)
      new.generate(system_prompt: system_prompt, user_prompt: user_prompt, context: context)
    end

    def generate(system_prompt:, user_prompt:, context: nil)
      messages = build_messages(system_prompt, user_prompt, context)

      response = with_timeout do
        client.chat(
          parameters: {
            model: model_name,
            messages: messages,
            max_tokens: max_tokens,
            temperature: 0.3
          }
        )
      end

      extract_content(response)
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
      raise TimeoutError, "AI service timed out: #{e.message}"
    rescue OpenAI::Error => e
      raise ProviderError, "AI provider error: #{e.message}"
    end

    private

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
      ENV.fetch("OPENAI_API_KEY") { raise Error, "OPENAI_API_KEY not configured" }
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
