module Ai
  module Providers
    class XiaomiMimo < Base
      DEFAULT_BASE_URL = "https://api.xiaomimimo.com/v1".freeze

      def provider_name = "mimo"
      def display_name = "Xiaomi MiMo"
      def model = ENV.fetch("MIMO_MODEL", "mimo-v2.5")
      def enabled? = true

      def generate(messages:, max_tokens:, stream: false)
        ensure_available!
        raise ArgumentError, "streaming is not implemented" if stream

        translate_errors do
          response = connection(base_url).post("chat/completions") do |request|
            request.headers["Authorization"] = "Bearer #{api_key}"
            request.body = { model: model, messages: messages, max_tokens: max_tokens,
              stream: false, thinking: { type: "disabled" } }
          end
          raise RequestError, provider_error(response) unless response.success?

          body = response.body
          content = body.dig("choices", 0, "message", "content")
          raise RequestError, "Xiaomi MiMo returned an empty response" if content.blank?

          Ai::Response.new(content: content.strip, provider: provider_name,
            model: body["model"].presence || model,
            input_tokens: body.dig("usage", "prompt_tokens"),
            output_tokens: body.dig("usage", "completion_tokens"),
            raw_request_id: response.headers["x-request-id"].presence || body["id"])
        end
      end

      protected

      def api_key
        ENV["MIMO_API_KEY"].presence || Rails.application.credentials.dig(:mimo, :api_key).presence
      end

      private

      def base_url = ENV.fetch("MIMO_BASE_URL", DEFAULT_BASE_URL)

      def provider_error(response)
        response.body.dig("error", "message").presence || "Xiaomi MiMo request failed (#{response.status})"
      end
    end
  end
end
