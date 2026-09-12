FactoryBot.define do
  factory :portal_status do
    association :public_service
    sequence(:code) { |n| "status-#{n}" }
    sequence(:name) { |n| "Status #{n}" }
    sequence(:position)
    active { true }
  end
end
