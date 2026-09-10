FactoryBot.define do
  factory :country do
    sequence(:name) { |n| "Country #{n}" }
    sequence(:code) { |n| format("%02d", n).last(2) }
    active { true }
  end
end
