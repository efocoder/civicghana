require "rails_helper"

RSpec.describe CaseAssessment::Evaluate do
  before { Rails.application.load_seed }

  let(:service) { PublicService.find_by!(slug: "official-consolidated-search") }

  describe "application lifecycle" do
    it "calculates days since completed application" do
      kase = create(:case,
        public_service: service,
        application_completed_on: Date.new(2026, 7, 30),
        payment_date: Date.new(2026, 7, 27))

      result = described_class.call(case_record: kase, assessment_date: Date.new(2026, 9, 10))

      expect(result[:lifecycle].days_since_completed_application).to eq(42)
      expect(result[:lifecycle].application_completed_on).to eq(Date.new(2026, 7, 30))
    end
  end

  describe "published rule with payment anchor" do
    it "returns within_timeframe when assessment date is before deadline" do
      kase = create(:case,
        public_service: service,
        application_completed_on: Date.new(2026, 7, 30),
        payment_date: Date.new(2026, 7, 27))

      result = described_class.call(case_record: kase, assessment_date: Date.new(2026, 8, 5))
      rule = result[:rule]

      expect(rule.assessment_state).to eq(:within_timeframe)
      expect(rule.published_days).to eq(14)
      expect(rule.rule_anchor_date).to eq(Date.new(2026, 7, 27))
      expect(rule.deadline).to eq(Date.new(2026, 8, 10))
      expect(rule.days_remaining).to eq(5)
    end

    it "returns due_today when assessment date equals deadline" do
      kase = create(:case,
        public_service: service,
        application_completed_on: Date.new(2026, 7, 30),
        payment_date: Date.new(2026, 7, 27))

      result = described_class.call(case_record: kase, assessment_date: Date.new(2026, 8, 10))
      rule = result[:rule]

      expect(rule.assessment_state).to eq(:due_today)
      expect(rule.deadline).to eq(Date.new(2026, 8, 10))
      expect(rule.days_remaining).to eq(0)
    end

    it "returns timeframe_exceeded when assessment date is after deadline" do
      kase = create(:case,
        public_service: service,
        application_completed_on: Date.new(2026, 7, 30),
        payment_date: Date.new(2026, 7, 27))

      result = described_class.call(case_record: kase, assessment_date: Date.new(2026, 9, 10))
      rule = result[:rule]

      expect(rule.assessment_state).to eq(:timeframe_exceeded)
      expect(rule.deadline).to eq(Date.new(2026, 8, 10))
      expect(rule.days_beyond).to eq(31)
    end

    it "returns insufficient_information when payment date is missing" do
      kase = create(:case,
        public_service: service,
        application_completed_on: Date.new(2026, 7, 30),
        payment_date: nil)

      result = described_class.call(case_record: kase, assessment_date: Date.new(2026, 9, 10))
      rule = result[:rule]

      expect(rule.assessment_state).to eq(:insufficient_information)
      expect(rule.rule_anchor_event).to eq("payment")
      expect(rule.rule_anchor_date).to be_nil
      expect(rule.deadline).to be_nil
    end
  end

  describe "published rule with completed_application anchor" do
    it "uses application_completed_on when anchor is completed_application" do
      rule = ServiceRule.find_by!(
        public_service: service,
        rule_type: :expected_duration_days,
        effective_from: Date.new(2020, 12, 23))
      rule.update!(anchor_event: :completed_application)

      kase = create(:case,
        public_service: service,
        application_completed_on: Date.new(2026, 7, 30),
        payment_date: Date.new(2026, 7, 27))

      result = described_class.call(case_record: kase, assessment_date: Date.new(2026, 8, 8))
      rule_result = result[:rule]

      expect(rule_result.assessment_state).to eq(:within_timeframe)
      expect(rule_result.rule_anchor_date).to eq(Date.new(2026, 7, 30))
      expect(rule_result.deadline).to eq(Date.new(2026, 8, 13))
    end
  end

  describe "source" do
    it "includes the verified source from the service rule" do
      kase = create(:case,
        public_service: service,
        application_completed_on: Date.new(2026, 7, 30),
        payment_date: Date.new(2026, 7, 27))

      result = described_class.call(case_record: kase, assessment_date: Date.new(2026, 8, 5))
      source = result[:rule].source

      expect(source.title).to eq("Land Act, 2020 (Act 1036)")
      expect(source.section_label).to eq("Section 222")
      expect(source.publisher).to eq("Republic of Ghana")
    end
  end
end
