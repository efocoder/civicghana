require "rails_helper"

RSpec.describe Ai::ResponseValidator do
  describe ".call" do
    it "passes when dates match known dates" do
      result = described_class.call(
        response: "The deadline was 10 August 2026.",
        known_dates: [ "10 August 2026" ]
      )

      expect(result.valid).to be true
      expect(result.errors).to be_empty
    end

    it "rejects when a date is invented" do
      result = described_class.call(
        response: "The deadline was 15 March 2026.",
        known_dates: [ "10 August 2026" ]
      )

      expect(result.valid).to be false
      expect(result.errors).to include(a_string_matching(/Invented date/))
    end

    it "rejects when a URL is invented" do
      result = described_class.call(
        response: "Visit https://fake-site.example.com for more info.",
        known_urls: [ "https://onlineservices.lc.gov.gh" ]
      )

      expect(result.valid).to be false
      expect(result.errors).to include(a_string_matching(/Invented URL/))
    end

    it "passes when URLs match known URLs" do
      result = described_class.call(
        response: "See https://onlineservices.lc.gov.gh for details.",
        known_urls: [ "https://onlineservices.lc.gov.gh" ]
      )

      expect(result.valid).to be true
    end

    it "passes with no invented content" do
      result = described_class.call(
        response: "The official search takes 14 days after payment.",
        known_dates: [ "10 August 2026" ],
        known_urls: [ "https://onlineservices.lc.gov.gh" ]
      )

      expect(result.valid).to be true
    end
  end
end
