FactoryBot.define do
  factory :case do
    association :public_service
    region { "Greater Accra" }
    application_completed_on { Date.current - 30.days }
    payment_date { nil }
    portal_created_on { nil }
  end
end
