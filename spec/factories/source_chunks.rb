FactoryBot.define do
  factory :source_chunk do
    association :source
    content { "Test chunk content about official search procedures." }
    section_label { nil }
    position { 1 }
    heading { "Test Heading" }
    page_number { nil }
    provision { nil }

    trait :land_act do
      content { "The Lands Commission shall issue the result of an official search within fourteen days after payment of the prescribed fees." }
      section_label { "Section 222" }
      provision { "Section 222" }
      heading { "Official Search Duration" }
    end

    trait :complaint do
      content { "The Lands Commission provides an official Feedback & Complaints channel for reporting service issues." }
      heading { "Filing a Complaint" }
    end
  end
end
