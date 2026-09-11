module Ai
  class CaseContextBuilder
    def self.call(...) = new(...).call

    def initialize(case_record:, rule_result:, evidence_comparison:, action_recommendation:)
      @case_record = case_record
      @rule_result = rule_result
      @evidence_comparison = evidence_comparison
      @action_recommendation = action_recommendation
    end

    def call
      parts = []
      parts << service_info
      parts << case_dates
      parts << rule_info
      parts << assessment_info
      parts << evidence_info
      parts << action_info
      parts.compact_blank.join("\n\n")
    end

    private

    attr_reader :case_record, :rule_result, :evidence_comparison, :action_recommendation

    def service_info
      "Service: #{case_record.public_service.name}\n" \
      "Institution: #{case_record.public_service.institution.name}"
    end

    def case_dates
      lines = []
      lines << "Application completed: #{format_date(case_record.application_completed_on)}"
      lines << "Payment date: #{format_date(case_record.payment_date)}" if case_record.payment_date
      lines << "Portal Date Created: #{format_date(case_record.portal_created_on)}" if case_record.portal_created_on
      lines << "Region: #{case_record.region}"
      lines.join("\n")
    end

    def rule_info
      return nil unless rule_result

      lines = []
      lines << "Published rule: #{rule_result.published_days} #{rule_result.service_rule.unit}"
      lines << "Rule anchor event: #{rule_result.rule_anchor_event}"
      lines << "Rule anchor date: #{format_date(rule_result.rule_anchor_date)}" if rule_result.rule_anchor_date
      lines << "Published deadline: #{format_date(rule_result.deadline)}" if rule_result.deadline
      lines << "Assessment date: #{format_date(rule_result.assessment_date)}"
      lines << "Days remaining: #{rule_result.days_remaining}" if rule_result.days_remaining
      lines << "Days beyond: #{rule_result.days_beyond}" if rule_result.days_beyond&.positive?
      lines << "Assessment state: #{rule_result.assessment_state}"
      lines << "Source: #{rule_result.source.title}, #{rule_result.source.section_label}"
      lines.join("\n")
    end

    def assessment_info
      return nil unless rule_result

      case rule_result.assessment_state
      when :within_timeframe
        "The case is still within the verified published timeframe."
      when :due_today
        "The verified published timeframe is reached today."
      when :timeframe_exceeded
        "The verified published timeframe has elapsed by #{rule_result.days_beyond} days."
      when :insufficient_information
        "The rule requires #{rule_result.rule_anchor_event} but that date was not provided."
      end
    end

    def evidence_info
      return nil unless evidence_comparison

      case evidence_comparison.status
      when :no_comparison
        "Evidence comparison: Not enough evidence to compare."
      when :consistent
        "Evidence comparison: The institutional update appears consistent with the portal snapshot."
      when :possible_discrepancy
        "Evidence comparison: Possible discrepancy — the institutional update indicates later progress than the portal shows."
      when :portal_unchanged
        "Evidence comparison: Portal information unchanged between two observations."
      when :possible_stale_public_status
        "Evidence comparison: Possible stale public status — portal unchanged across two observations, but a later institutional update indicates greater progress."
      when :insufficient_information
        "Evidence comparison: Cannot structurally compare the evidence."
      end
    end

    def action_info
      return nil unless action_recommendation

      "Recommended action: #{action_recommendation.action_type}\n" \
      "Reason code: #{action_recommendation.explanation_code}\n" \
      "Reasons: #{action_recommendation.reasons.join('. ')}"
    end

    def format_date(date)
      return "not provided" unless date
      date.strftime("%-d %B %Y")
    end
  end
end
