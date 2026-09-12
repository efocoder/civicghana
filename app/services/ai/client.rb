module Ai
  class Client
    Error = Ai::Providers::Base::Error
    ConfigurationError = Ai::Providers::Base::ConfigurationError
    TimeoutError = Ai::Providers::Base::TimeoutError
    ProviderError = Ai::Providers::Base::RequestError
    DisabledError = Ai::Providers::Base::DisabledError

    def self.generate(provider: nil, system_prompt:, user_prompt:, context: nil, task: nil)
      new.generate(provider: provider, system_prompt: system_prompt,
        user_prompt: user_prompt, context: context, task: task)
    end

    def generate(provider: nil, system_prompt:, user_prompt:, context: nil, task: nil)
      if provider.present? && provider.to_s != Ai::ProviderRegistry.default_name
        raise Ai::ProviderRegistry::UnknownProvider, "Unknown AI provider"
      end
      adapter = Ai::ProviderRegistry.fetch
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      response = adapter.generate(
        messages: build_messages(system_prompt, user_prompt, context),
        max_tokens: ENV.fetch("AI_MAX_TOKENS", "1000").to_i
      )
      log_result(response, task, started_at)
      response
    rescue Ai::Providers::Base::Error
      log_failure(Ai::ProviderRegistry.default_name, task, started_at)
      raise
    end

    private

    def build_messages(system_prompt, user_prompt, context)
      system_content = system_prompt.dup
      system_content << "\n\nVerified CivicRoute context:\n\n#{context}" if context.present?
      [ { role: "system", content: system_content }, { role: "user", content: user_prompt } ]
    end

    def log_result(response, task, started_at)
      Rails.logger.info({ event: "ai_request", provider: response.provider,
        model: response.model, task_type: task, success: true, duration_ms: elapsed_ms(started_at),
        input_tokens: response.input_tokens, output_tokens: response.output_tokens }.to_json)
    end

    def log_failure(provider, task, started_at)
      Rails.logger.warn({ event: "ai_request", provider: provider,
        task_type: task, success: false, duration_ms: elapsed_ms(started_at) }.to_json)
    end

    def elapsed_ms(started_at)
      return nil unless started_at

      ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
    end
  end
end
