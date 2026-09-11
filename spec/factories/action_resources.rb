FactoryBot.define do
  factory :action_resource do
    association :institution
    association :source
    name { "Test Resource" }
    resource_type { :contact }
    purpose { "Test purpose" }
    url { "https://example.com" }
    last_verified_at { Time.current }
    active { true }

    trait :contact do
      resource_type { :contact }
      name { "Lands Commission — Contact" }
    end

    trait :complaint do
      resource_type { :complaint }
      name { "Lands Commission — Complaints" }
    end

    trait :rti do
      resource_type { :rti }
      name { "RTI Commission" }
    end

    trait :administrative_redress do
      resource_type { :administrative_redress }
      name { "CHRAJ" }
    end

    trait :inactive do
      active { false }
    end
  end
end
