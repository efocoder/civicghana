FactoryBot.define do
  factory :case_observation do
    association :case
    observation_type { :portal }
    observed_on { Date.current }
    overall_status { nil }
  end
end
