module ActionRecommendation
  class Evaluate
    Result = Data.define(
      :action_type,
      :explanation_code,
      :reasons,
      :action_resource,
      :secondary_actions
    )

    def self.call(...) = new(...).call

    def initialize(case_record:, rule_result:, evidence_comparison:, information_need: nil)
      @case_record = case_record
      @rule_result = rule_result
      @evidence_comparison = evidence_comparison
      @information_need = information_need&.to_sym
      @existing_actions = case_record.case_actions.order(:created_at)
    end

    def call
      primary = determine_primary_action
      secondary = determine_secondary_actions(primary.action_type)

      Result.new(
        action_type: primary.action_type,
        explanation_code: primary.explanation_code,
        reasons: primary.reasons,
        action_resource: primary.action_resource,
        secondary_actions: secondary
      )
    end

    private

    attr_reader :case_record, :rule_result, :evidence_comparison, :existing_actions

    ActionSuggestion = Data.define(:action_type, :explanation_code, :reasons, :action_resource)

    def determine_primary_action
      if within_timeframe?
        return ActionSuggestion.new(
          action_type: :monitor,
          explanation_code: :within_published_timeframe,
          reasons: [ "Your case is still within the verified published timeframe." ],
          action_resource: nil
        )
      end

      if due_today?
        return ActionSuggestion.new(
          action_type: :monitor,
          explanation_code: :within_published_timeframe,
          reasons: [ "The verified published timeframe is reached today." ],
          action_resource: nil
        )
      end

      if has_clarification? && has_unresolved_issue?
        resource = find_resource(:complaint)
        return ActionSuggestion.new(
          action_type: :complaint,
          explanation_code: :clarification_unresolved,
          reasons: [
            "A follow-up was recorded but the issue remains unresolved.",
            "A formal complaint may help document the service issue."
          ],
          action_resource: resource
        )
      end

      if has_clarification? && !has_response_to_clarification?
        return ActionSuggestion.new(
          action_type: :monitor,
          explanation_code: :clarification_already_taken,
          reasons: [ "You have already recorded a follow-up. Add the institution's response when you receive one." ],
          action_resource: nil
        )
      end

      if has_stale_status?
        if has_clarification? && has_unresolved_issue?
          resource = find_resource(:complaint)
          return ActionSuggestion.new(
            action_type: :complaint,
            explanation_code: :stale_status_after_followup,
            reasons: [
              "The portal information remained unchanged across two observations.",
              "A later institutional update indicated greater progress.",
              "A prior follow-up was already recorded."
            ],
            action_resource: resource
          )
        else
          resource = find_resource(:contact)
          return ActionSuggestion.new(
            action_type: :clarification,
            explanation_code: :stale_status_after_followup,
            reasons: [
              "The portal information remained unchanged across two observations.",
              "A later institutional update indicated greater progress.",
              "No written clarification has yet been recorded."
            ],
            action_resource: resource
          )
        end
      end

      if has_discrepancy? && !has_clarification?
        resource = find_resource(:contact)
        return ActionSuggestion.new(
          action_type: :clarification,
          explanation_code: :evidence_discrepancy_no_followup,
          reasons: [
            "The portal information and the later institutional update do not appear consistent.",
            "A written clarification can help establish a clearer evidence trail."
          ],
          action_resource: resource
        )
      end

      if timeframe_exceeded? && !has_clarification?
        resource = find_resource(:contact)
        return ActionSuggestion.new(
          action_type: :clarification,
          explanation_code: :timeframe_exceeded_no_followup,
          reasons: [
            "The verified published timeframe has elapsed.",
            "No written clarification has yet been recorded."
          ],
          action_resource: resource
        )
      end

      ActionSuggestion.new(
        action_type: :monitor,
        explanation_code: :within_published_timeframe,
        reasons: [ "Continue monitoring the public portal and record any new information you receive." ],
        action_resource: nil
      )
    end

    def determine_secondary_actions(primary_type)
      secondary = []

      if @information_need == :specific_information && primary_type != :rti
        resource = find_resource(:rti)
        if resource
          secondary << ActionSuggestion.new(
            action_type: :rti,
            explanation_code: :specific_information_requested,
            reasons: [ "If you need access to recorded information held by a public institution, an RTI request may be relevant." ],
            action_resource: resource
          )
        end
      end

      if has_unresolved_issue? && primary_type != :chraj
        resource = find_resource(:administrative_redress)
        if resource
          secondary << ActionSuggestion.new(
            action_type: :chraj,
            explanation_code: :institutional_resolution_unsuccessful,
            reasons: [ "If your efforts to resolve the issue with the institution have been unsuccessful, CHRAJ may be an appropriate administrative-justice avenue." ],
            action_resource: resource
          )
        end
      end

      secondary
    end

    def within_timeframe?
      rule_result.assessment_state == :within_timeframe
    end

    def due_today?
      rule_result.assessment_state == :due_today
    end

    def timeframe_exceeded?
      rule_result.assessment_state == :timeframe_exceeded
    end

    def has_discrepancy?
      evidence_comparison.status == :possible_discrepancy
    end

    def has_stale_status?
      evidence_comparison.status == :possible_stale_public_status
    end

    def has_clarification?
      existing_actions.where(action_type: :clarification).where.not(status: :cancelled).exists?
    end

    def has_response_to_clarification?
      existing_actions.where(action_type: :clarification, status: :responded).exists?
    end

    def has_unresolved_issue?
      existing_actions.where(action_type: :clarification, outcome: :outcome_unresolved).exists? ||
        existing_actions.where(action_type: :complaint, status: :unresolved).exists?
    end

    def has_prior_institutional_contact?
      existing_actions.where(action_type: %i[clarification complaint]).where.not(status: :cancelled).exists?
    end

    def find_resource(resource_type)
      institution = case_record.public_service.institution
      ActionResource.active.verified.joins(:source).merge(Source.verified)
        .where(institution: institution, resource_type: resource_type).first
    end
  end
end
