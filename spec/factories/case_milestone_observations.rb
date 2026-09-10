FactoryBot.define do
  factory :case_milestone_observation do
    association :case_observation
    association :process_step
    status { "Pending" }
  end
end
