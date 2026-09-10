FactoryBot.define do
  factory :action_path do
    association :public_service
    association :source
    sequence(:sequence)
    action_type { :check }
    sequence(:title) { |n| "Action #{n}" }
    instructions { "Take this action." }
    conditions { {} }
    active { true }
  end
end
