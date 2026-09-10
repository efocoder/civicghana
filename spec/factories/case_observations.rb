FactoryBot.define do
  factory :case_observation do
    association :case
    observation_type { :portal }
    observed_on { Date.current }
    overall_status { nil }
    summary { nil }
    progress_claim { nil }
    reported_process_step { nil }

    trait :portal do
      observation_type { :portal }
    end

    trait :phone do
      observation_type { :phone }
      progress_claim { :unspecified }
      summary { "Test update" }
    end

    trait :near_completion do
      observation_type { :phone }
      progress_claim { :near_completion }
      summary { "Near completion" }
    end

    trait :at_milestone do
      observation_type { :phone }
      progress_claim { :public_milestone }
      association :reported_process_step
      summary { "At milestone" }
    end
  end
end
