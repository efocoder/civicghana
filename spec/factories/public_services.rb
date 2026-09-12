FactoryBot.define do
  factory :public_service do
    association :institution
    sequence(:name) { |n| "Public Service #{n}" }
    sequence(:slug) { |n| "public-service-#{n}" }
    description { "A public service." }
    service_category { "general" }
    support_level { :trackable }
    case_enabled { true }
    tracks_portal_milestones { true }
    requires_region { true }
    active { true }
  end
end
