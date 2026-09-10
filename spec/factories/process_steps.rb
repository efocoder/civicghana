FactoryBot.define do
  factory :process_step do
    association :public_service
    sequence(:sequence)
    sequence(:name) { |n| "Step #{n}" }
    description { "A published process step." }
  end
end
