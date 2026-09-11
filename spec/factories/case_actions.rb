FactoryBot.define do
  factory :case_action do
    association :case
    action_type { :clarification }
    status { :recommended }
    recommended_on { Date.current }

    trait :clarification do
      action_type { :clarification }
    end

    trait :complaint do
      action_type { :complaint }
    end

    trait :rti do
      action_type { :rti }
    end

    trait :chraj do
      action_type { :chraj }
    end

    trait :monitor do
      action_type { :monitor }
    end

    trait :taken do
      status { :taken }
      taken_on { Date.current }
    end

    trait :responded do
      status { :responded }
      taken_on { Date.current }
      outcome { :received_response }
    end

    trait :unresolved do
      status { :unresolved }
      taken_on { Date.current }
      outcome { :outcome_unresolved }
    end

    trait :cancelled do
      status { :cancelled }
    end
  end
end
