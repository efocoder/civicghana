FactoryBot.define do
  factory :service_source do
    association :public_service
    association :source
    purpose { "Service guidance" }
    primary { false }
  end
end
