module ActionDrafts
  class Complaint
    def self.call(...) = new(...).call

    def initialize(case_record:, observations:, rule_result:, prior_actions:)
      @case_record = case_record
      @observations = observations
      @rule_result = rule_result
      @prior_actions = prior_actions
    end

    def call
      {
        subject: "Service complaint — #{case_record.public_service.name}",
        body: build_body
      }
    end

    private

    attr_reader :case_record, :observations, :rule_result, :prior_actions

    def build_body
      lines = []
      lines << "I wish to raise a service complaint concerning the processing and public"
      lines << "tracking information for my #{case_record.public_service.name} application."
      lines << ""
      lines << "Application completed:"
      lines << format_date(case_record.application_completed_on)
      lines << ""

      if case_record.payment_date
        lines << "Payment date:"
        lines << format_date(case_record.payment_date)
        lines << ""
      end

      if observations.any?
        lines << "Relevant portal observations:"
        observations.select(&:portal?).each do |obs|
          lines << "  #{format_date(obs.observed_on)}: Portal snapshot recorded"
          obs.case_milestone_observations.includes(:process_step).order("process_steps.position").each do |m|
            lines << "    #{m.process_step.name}: #{m.status}"
          end
        end
        lines << ""
      end

      if prior_actions.any?
        lines << "Follow-up already made:"
        prior_actions.each do |action|
          lines << "  #{action.action_type.humanize}: #{format_date(action.recommended_on)}"
          if action.taken_on
            lines << "    Taken: #{format_date(action.taken_on)}"
          end
          if action.outcome
            lines << "    Outcome: #{action.outcome.humanize}"
          end
        end
        lines << ""
      end

      lines << "Issue:"
      if rule_result&.assessment_state == :timeframe_exceeded
        lines << "The verified published timeframe has elapsed without resolution."
      end
      lines << ""

      lines << "Requested resolution:"
      lines << "Please provide a clear written status update and advise what action remains"
      lines << "necessary for completion."
      lines << ""

      lines << "Supporting CivicRoute evidence summary:"
      lines << build_evidence_chronology

      lines.join("\n")
    end

    def build_evidence_chronology
      events = []
      events << "#{format_date(case_record.application_completed_on)}: Application completed"
      events << "#{format_date(case_record.payment_date)}: Payment" if case_record.payment_date
      events << "#{format_date(case_record.portal_created_on)}: Portal Date Created" if case_record.portal_created_on

      observations.each do |obs|
        if obs.portal?
          events << "#{format_date(obs.observed_on)}: Portal snapshot recorded"
        else
          events << "#{format_date(obs.observed_on)}: #{obs.observation_type.humanize} update"
        end
      end

      events.map { |e| "  #{e}" }.join("\n")
    end

    def format_date(date)
      date.strftime("%-d %B %Y")
    end
  end
end
