require "rails_helper"

RSpec.describe Ai::Client do
  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("OPENAI_API_KEY").and_return("test-key")
    allow(ENV).to receive(:fetch).with("OPENAI_MODEL", anything).and_return("gpt-4o-mini")
    allow(ENV).to receive(:fetch).with("AI_MAX_TOKENS", anything).and_return("1000")
    allow(ENV).to receive(:fetch).with("AI_TIMEOUT", anything).and_return("30")
  end

  describe ".generate" do
    it "returns the content from the API response" do
      response = {
        "choices" => [
          { "message" => { "content" => "This is the answer." } }
        ]
      }

      client = instance_double(OpenAI::Client)
      allow(OpenAI::Client).to receive(:new).and_return(client)
      allow(client).to receive(:chat).and_return(response)

      result = described_class.generate(
        system_prompt: "You are a test assistant.",
        user_prompt: "Hello"
      )

      expect(result).to eq("This is the answer.")
    end

    it "raises TimeoutError on timeout" do
      client = instance_double(OpenAI::Client)
      allow(OpenAI::Client).to receive(:new).and_return(client)
      allow(client).to receive(:chat).and_raise(Faraday::TimeoutError.new("timeout"))

      expect {
        described_class.generate(system_prompt: "test", user_prompt: "test")
      }.to raise_error(Ai::Client::TimeoutError)
    end

    it "raises ProviderError on OpenAI error" do
      client = instance_double(OpenAI::Client)
      allow(OpenAI::Client).to receive(:new).and_return(client)
      allow(client).to receive(:chat).and_raise(OpenAI::Error.new("rate limited"))

      expect {
        described_class.generate(system_prompt: "test", user_prompt: "test")
      }.to raise_error(Ai::Client::ProviderError)
    end

    it "raises ProviderError on provider rate limits without retrying" do
      client = instance_double(OpenAI::Client)
      allow(OpenAI::Client).to receive(:new).and_return(client)
      allow(client).to receive(:chat).and_raise(Faraday::TooManyRequestsError.new("rate limited"))

      expect {
        described_class.generate(system_prompt: "test", user_prompt: "test")
      }.to raise_error(Ai::Client::ProviderError, /rate limit/)
      expect(client).to have_received(:chat).once
    end
  end
end
