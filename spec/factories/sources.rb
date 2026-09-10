FactoryBot.define do
  factory :source do
    publisher { "Test Publisher" }
    sequence(:title) { |n| "Test Source #{n}" }
    sequence(:url) { |n| "https://example.gov.gh/source/#{n}" }
    authority_type { :official_service }
    summary { "A verified test source." }
    verified_at { Time.current }
    content_hash { Digest::SHA256.hexdigest(title) }
    active { true }
  end
end
