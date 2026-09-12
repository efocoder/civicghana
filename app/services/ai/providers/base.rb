require "faraday"

module Ai
  module Providers
    class Base
      class Error < StandardError; end
      class ConfigurationError < Error; end
      class DisabledError < Error; end
      class TimeoutError < Error; end
      class RequestError < Error; end

      def generate(messages:, max_tokens:, stream: false) = raise(NotImplementedError)
      def available? = enabled? && configured?
      def configured? = api_key.present? && model.present?
      def enabled? = true
      def provider_name = raise(NotImplementedError)
      def display_name = raise(NotImplementedError)
      def model = raise(NotImplementedError)

      protected

      def api_key = raise(NotImplementedError)

      def ensure_available!
        raise DisabledError, "#{display_name} is disabled" unless enabled?
        raise ConfigurationError, "#{display_name} is not configured" unless configured?
      end

      def timeout = ENV.fetch("AI_TIMEOUT", "30").to_i

      def connection(base_url)
        ::Faraday.new(url: base_url) do |faraday|
          faraday.request :json
          faraday.response :json
          faraday.options.timeout = timeout
          faraday.options.open_timeout = [ timeout, 10 ].min
          faraday.adapter Faraday.default_adapter
        end
      end

      def truthy_env?(name, default: true)
        ActiveModel::Type::Boolean.new.cast(ENV.fetch(name, default.to_s))
      end

      def translate_errors
        yield
      rescue ::Faraday::TimeoutError, ::Faraday::ConnectionFailed => error
        raise TimeoutError, error.message
      rescue ::Faraday::Error => error
        raise RequestError, error.message
      end
    end
  end
end
