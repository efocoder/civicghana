module ActionDrafts
  class Clarification
    def self.call(...) = new(...).call

    def initialize(case_record:, observation:, rule_result:)
      @case_record = case_record
      @observation = observation
      @rule_result = rule_result
    end

    def call
      {
        subject: "Request for status clarification — #{case_record.public_service.name}",
        body: build_body
      }
    end

    private

    attr_reader :case_record, :observation, :rule_result

    def build_body
      lines = []
      lines << "I am requesting clarification on the current status of my application for"
      lines << "a #{case_record.public_service.name}."
      lines << ""
      lines << "Application completed:"
      lines << format_date(case_record.application_completed_on)
      lines << ""

      if case_record.payment_date
        lines << "Payment date:"
        lines << format_date(case_record.payment_date)
        lines << ""
      end

      if case_record.portal_created_on
        lines << "Portal Date Created:"
        lines << format_date(case_record.portal_created_on)
        lines << ""
      end

      if observation
        lines << "The public portal was last observed on:"
        lines << format_date(observation.observed_on)
        lines << ""

        milestones = observation.case_milestone_observations.includes(:process_step).order("process_steps.position")
        if milestones.any?
          lines << "At that time, it showed:"
          milestones.each do |m|
            lines << "  #{m.process_step.name}: #{m.status}"
          end
          lines << ""
        end
      end

      if rule_result && rule_result.assessment_state != :insufficient_information
        lines << "The verified published timeframe available to me is:"
        lines << "#{rule_result.published_days} #{rule_result.service_rule.unit}"
        lines << "Based on: #{rule_result.source.title}, #{rule_result.source.section_label}"
        lines << ""
      end

      lines << "I would appreciate written clarification on:"
      lines << "1. the current recorded status of the application; and"
      lines << "2. the expected next step or completion timeframe."
      lines << ""
      lines << "Thank you."

      lines.join("\n")
    end

    def format_date(date)
      date.strftime("%-d %B %Y")
    end
  end
end
