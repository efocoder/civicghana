FactoryBot.define do
  factory :public_service do
    association :institution
    sequence(:name) { |n| "Public Service #{n}" }
    sequence(:slug) { |n| "public-service-#{n}" }
    description { "A public service." }
    service_category { "general" }
    active { true }
  end
end
