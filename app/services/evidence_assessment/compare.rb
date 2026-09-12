module EvidenceAssessment
  class Compare
    Result = Data.define(
      :status,
      :portal_observation,
      :comparison_observation,
      :explanation_code,
      :portal_changed,
      :supporting_evidence
    )

    STATUSES = %w[
      no_comparison
      consistent
      possible_discrepancy
      portal_unchanged
      possible_stale_public_status
      insufficient_information
    ].freeze

    def self.call(...) = new(...).call

    def initialize(case_record:)
      @case_record = case_record
      @observations = case_record.case_observations.includes(:case_milestone_observations, :reported_process_step).order(:observed_on, :created_at)
    end

    def call
      portal_observations = @observations.select(&:portal?)
      non_portal_observations = @observations.reject(&:portal?)

      return no_comparison_result if @observations.size < 2
      return no_comparison_result if portal_observations.empty?

      latest_portal = portal_observations.last
      latest_non_portal = non_portal_observations.last

      if portal_observations.size >= 2
        previous_portal = portal_observations[-2]
        if portal_snapshots_identical?(previous_portal, latest_portal)
          if latest_non_portal && non_portal_between?(previous_portal, latest_portal, latest_non_portal) && indicates_later_progress?(latest_non_portal)
            return stale_result(latest_portal, previous_portal, latest_non_portal)
          end
          return portal_unchanged_result(latest_portal, previous_portal)
        end
      end

      return no_comparison_result unless latest_non_portal

      compare_evidence(latest_portal, latest_non_portal)
    end

    private

    def no_comparison_result
      Result.new(
        status: :no_comparison,
        portal_observation: nil,
        comparison_observation: nil,
        explanation_code: :only_portal_evidence,
        portal_changed: nil,
        supporting_evidence: []
      )
    end

    def portal_unchanged_result(current, previous)
      Result.new(
        status: :portal_unchanged,
        portal_observation: current,
        comparison_observation: previous,
        explanation_code: :identical_snapshots,
        portal_changed: false,
        supporting_evidence: [current, previous]
      )
    end

    def stale_result(portal, previous_portal, non_portal)
      Result.new(
        status: :possible_stale_public_status,
        portal_observation: portal,
        comparison_observation: non_portal,
        explanation_code: :portal_unchanged_after_later_update,
        portal_changed: false,
        supporting_evidence: [previous_portal, non_portal, portal]
      )
    end

    def compare_evidence(portal, non_portal)
      portal_position = portal_progress_position(portal)
      claimed_position = claimed_progress_position(non_portal)

      if claimed_position.nil?
        return insufficient_result(portal, non_portal)
      end

      if claimed_position == portal_position
        consistent_result(portal, non_portal)
      elsif claimed_position > portal_position || non_portal.near_completion? || non_portal.completed?
        discrepancy_result(portal, non_portal)
      else
        insufficient_result(portal, non_portal)
      end
    end

    def consistent_result(portal, non_portal)
      Result.new(
        status: :consistent,
        portal_observation: portal,
        comparison_observation: non_portal,
        explanation_code: :evidence_agrees,
        portal_changed: nil,
        supporting_evidence: [portal, non_portal]
      )
    end

    def discrepancy_result(portal, non_portal)
      Result.new(
        status: :possible_discrepancy,
        portal_observation: portal,
        comparison_observation: non_portal,
        explanation_code: :later_progress_than_portal,
        portal_changed: nil,
        supporting_evidence: [portal, non_portal]
      )
    end

    def insufficient_result(portal, non_portal)
      Result.new(
        status: :insufficient_information,
        portal_observation: portal,
        comparison_observation: non_portal,
        explanation_code: :cannot_compare_structurally,
        portal_changed: nil,
        supporting_evidence: [portal, non_portal]
      )
    end

    def portal_snapshots_identical?(obs1, obs2)
      statuses1 = obs1.case_milestone_observations.includes(:process_step).map { |m| [m.process_step.name, m.status] }.sort
      statuses2 = obs2.case_milestone_observations.includes(:process_step).map { |m| [m.process_step.name, m.status] }.sort
      statuses1 == statuses2
    end

    def non_portal_between?(portal1, portal2, non_portal)
      non_portal.observed_on > portal1.observed_on && non_portal.observed_on < portal2.observed_on
    end

    def portal_progress_position(observation)
      milestones = observation.case_milestone_observations.includes(:process_step)
      status_options = @case_record.public_service.portal_statuses.active.index_by { |option| option.name }
      ranked = milestones.filter_map do |milestone|
        option = status_options[milestone.status] || status_options.values.find { |candidate| candidate.code == milestone.status }
        next unless option

        [milestone.process_step.position, option.position]
      end
      return 0 if ranked.empty?

      current_status_position = ranked.map(&:last).min
      ranked.select { |_, status_position| status_position == current_status_position }.map(&:first).min
    end

    def claimed_progress_position(observation)
      case observation.progress_claim
      when "public_milestone"
        observation.reported_process_step&.sequence
      when "near_completion"
        999
      when "completed"
        1000
      when "unspecified"
        nil
      when "other_claim"
        nil
      else
        nil
      end
    end

    def indicates_later_progress?(observation)
      return false if observation.unspecified?

      claimed = claimed_progress_position(observation)
      return false if claimed.nil?

      true
    end
  end
end
