FactoryBot.define do
  factory :institution do
    association :country
    sequence(:name) { |n| "Public Institution #{n}" }
    official_url { "https://example.gov.gh" }
    description { "A public institution." }
    active { true }
  end
end
