FactoryBot.define do
  factory :service_rule do
    association :public_service
    association :source
    rule_type { :expected_duration_days }
    value { 14 }
    unit { "days after payment" }
    effective_from { Date.new(2020, 12, 23) }
    verified_at { Time.current }
    active { true }
  end
end
