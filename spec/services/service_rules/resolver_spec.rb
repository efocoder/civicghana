require "rails_helper"

RSpec.describe ServiceRules::Resolver do
  let(:service) { create(:public_service) }
  let(:source) { create(:source) }

  it "returns the active verified rule effective on the requested date" do
    rule = create(:service_rule, public_service: service, source: source,
      effective_from: Date.new(2020, 1, 1), effective_to: nil)

    expect(described_class.call(public_service: service, rule_type: :expected_duration_days, on: Date.new(2024, 1, 1))).to eq(rule)
  end

  it "does not return an expired rule" do
    create(:service_rule, public_service: service, source: source,
      effective_from: Date.new(2020, 1, 1), effective_to: Date.new(2020, 12, 31))

    expect {
      described_class.call(public_service: service, rule_type: :expected_duration_days, on: Date.new(2021, 1, 1))
    }.to raise_error(described_class::NotFound)
  end

  it "does not return a future rule" do
    create(:service_rule, public_service: service, source: source,
      effective_from: Date.new(2030, 1, 1))

    expect {
      described_class.call(public_service: service, rule_type: :expected_duration_days, on: Date.new(2029, 12, 31))
    }.to raise_error(described_class::NotFound)
  end

  it "does not return an inactive rule or inactive source" do
    create(:service_rule, public_service: service, source: source, active: false)
    create(:service_rule, public_service: service, source: create(:source, active: false))

    expect {
      described_class.call(public_service: service, rule_type: :expected_duration_days)
    }.to raise_error(described_class::NotFound)
  end

  it "rejects overlapping verified rules" do
    create(:service_rule, public_service: service, source: source,
      effective_from: Date.new(2020, 1, 1), effective_to: Date.new(2025, 12, 31))
    create(:service_rule, public_service: service, source: create(:source),
      effective_from: Date.new(2025, 1, 1), effective_to: nil)

    expect {
      described_class.call(public_service: service, rule_type: :expected_duration_days, on: Date.new(2025, 6, 1))
    }.to raise_error(described_class::Ambiguous)
  end
end
