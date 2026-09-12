require "rails_helper"

RSpec.describe Ai::Client do
  let(:response) do
    Ai::Response.new(content: "This is the answer.", provider: "mimo", model: "mimo-v2.5",
      input_tokens: 2, output_tokens: 3, raw_request_id: "req_1")
  end

  it "dispatches through the selected provider and returns a normalized response" do
    adapter = instance_double(Ai::Providers::XiaomiMimo, generate: response)
    allow(Ai::ProviderRegistry).to receive(:fetch).with("mimo").and_return(adapter)
    result = described_class.generate(provider: "mimo", task: :service_question,
      system_prompt: "You are grounded.", user_prompt: "Hello", context: "Verified context")
    expect(result).to eq(response)
    expect(adapter).to have_received(:generate).with(hash_including(max_tokens: an_instance_of(Integer)))
  end

  it "rejects unknown providers" do
    expect {
      described_class.generate(provider: "unknown", system_prompt: "test", user_prompt: "test")
    }.to raise_error(Ai::ProviderRegistry::UnknownProvider)
  end
end
