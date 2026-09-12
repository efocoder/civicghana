require "rails_helper"

RSpec.describe "AI provider adapters" do
  it "normalizes a MiMo-compatible response" do
    stub_request(:post, "https://api.xiaomimimo.com/v1/chat/completions")
      .to_return(status: 200, body: { id: "mimo_req", model: "mimo-v2.5",
        choices: [ { message: { content: "MiMo answer" } } ], usage: { prompt_tokens: 4, completion_tokens: 2 } }.to_json,
        headers: { "Content-Type" => "application/json", "x-request-id" => "mimo_req" })
    provider = Ai::Providers::XiaomiMimo.new
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("MIMO_API_KEY").and_return("test-key")
    result = provider.generate(messages: [ { role: "user", content: "Hi" } ], max_tokens: 10)
    expect(result.content).to eq("MiMo answer")
    expect(result.provider).to eq("mimo")
  end

end
