module CaseAssessment
  class Evaluate
    LifecycleResult = Data.define(
      :days_since_completed_application,
      :application_completed_on,
      :observed_on
    )

    RuleResult = Data.define(
      :assessment_state,
      :published_days,
      :deadline,
      :assessment_date,
      :days_remaining,
      :days_beyond,
      :rule_anchor_date,
      :rule_anchor_event,
      :service_rule,
      :source
    )

    STATES = %w[within_timeframe due_today timeframe_exceeded insufficient_information].freeze

    def self.call(...) = new(...).call

    def initialize(case_record:, assessment_date:)
      @case_record = case_record
      @assessment_date = assessment_date
    end

    def call
      { lifecycle: build_lifecycle, rule: build_rule }
    end

    private

    attr_reader :case_record, :assessment_date

    def build_lifecycle
      days = (assessment_date - case_record.application_completed_on).to_i

      LifecycleResult.new(
        days_since_completed_application: days,
        application_completed_on: case_record.application_completed_on,
        observed_on: assessment_date
      )
    end

    def build_rule
      rule = ServiceRules::Resolver.call(
        public_service: case_record.public_service,
        rule_type: :expected_duration_days,
        on: case_record.application_completed_on
      )

      anchor_date = resolve_anchor_date(rule)

      unless anchor_date
        return RuleResult.new(
          assessment_state: :insufficient_information,
          published_days: rule.value,
          deadline: nil,
          assessment_date: assessment_date,
          days_remaining: nil,
          days_beyond: 0,
          rule_anchor_date: nil,
          rule_anchor_event: rule.anchor_event,
          service_rule: rule,
          source: rule.source
        )
      end

      deadline = calculate_deadline(anchor_date, rule)
      days_remaining = (deadline - assessment_date).to_i
      days_beyond = days_remaining.negative? ? days_remaining.abs : 0

      state = if days_remaining.positive?
        :within_timeframe
      elsif days_remaining.zero?
        :due_today
      else
        :timeframe_exceeded
      end

      RuleResult.new(
        assessment_state: state,
        published_days: rule.value,
        deadline: deadline,
        assessment_date: assessment_date,
        days_remaining: days_remaining,
        days_beyond: days_beyond,
        rule_anchor_date: anchor_date,
        rule_anchor_event: rule.anchor_event,
        service_rule: rule,
        source: rule.source
      )
    end

    def resolve_anchor_date(rule)
      case rule.anchor_event
      when "payment"
        case_record.payment_date
      when "completed_application"
        case_record.application_completed_on
      when "portal_created"
        case_record.portal_created_on
      else
        nil
      end
    end

    def calculate_deadline(anchor_date, rule)
      unit = rule.duration_unit.to_s.downcase
      if unit.include?("month")
        anchor_date.advance(months: rule.duration_value)
      elsif unit.include?("week")
        anchor_date + rule.duration_value.weeks
      else
        anchor_date + rule.duration_value.days
      end
    end
  end
end
