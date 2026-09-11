class CaseActionsController < ApplicationController
  before_action :load_case
  before_action :load_assessment

  def new
    @action_type = params[:action_type]&.to_sym
    unless CaseAction.action_types.key?(@action_type.to_s)
      return redirect_to @case, alert: "Invalid action type."
    end

    @action = @case.case_actions.build(
      action_type: @action_type,
      recommended_on: Date.current,
      status: :recommended
    )

    @action_resource = find_resource(@action_type)
    @draft = build_draft(@action_type)
    @secondary_actions = @action_recommendation.secondary_actions
  end

  def create
    @action = @case.case_actions.build(action_params)
    @action.recommended_on ||= Date.current

    if @action.save
      redirect_to case_case_action_path(@case, @action)
    else
      @action_type = @action.action_type&.to_sym
      @action_resource = @action.action_resource || find_resource(@action_type)
      @draft = build_draft(@action_type)
      @secondary_actions = []
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @action = @case.case_actions.find(params[:id])
    @action_resource = @action.action_resource
  end

  def update
    @action = @case.case_actions.find(params[:id])

    if @action.update(update_params)
      if @action.taken? && @action.outcome == "received_response"
        redirect_to new_case_observation_path(@case)
      else
        redirect_to @case
      end
    else
      @action_resource = @action.action_resource
      render :show, status: :unprocessable_entity
    end
  end

  private

  def load_case
    @case = Case.includes(:public_service, case_observations: { case_milestone_observations: :process_step }).find(params[:case_id])
  end

  def load_assessment
    observations = @case.case_observations.includes(:case_milestone_observations, :reported_process_step).order(:observed_on, :created_at)
    @latest_portal = observations.select(&:portal?).last

    assessment = CaseAssessment::Evaluate.call(
      case_record: @case,
      assessment_date: @latest_portal&.observed_on || Date.current
    )
    @rule_result = assessment[:rule]
    @evidence_comparison = EvidenceAssessment::Compare.call(case_record: @case)

    @action_recommendation = ActionRecommendation::Evaluate.call(
      case_record: @case,
      rule_result: @rule_result,
      evidence_comparison: @evidence_comparison,
      information_need: params[:need]
    )
  end

  def find_resource(action_type)
    resource_type = case action_type
    when :clarification then :contact
    when :complaint then :complaint
    when :rti then :rti
    when :chraj then :administrative_redress
    else nil
    end
    return nil unless resource_type

    institution = @case.public_service.institution
    ActionResource.active.verified.joins(:source).merge(Source.verified)
      .where(institution: institution, resource_type: resource_type).first
  end

  def build_draft(action_type)
    case action_type
    when :clarification
      ActionDrafts::Clarification.call(
        case_record: @case,
        observation: @latest_portal,
        rule_result: @rule_result
      )
    when :complaint
      observations = @case.case_observations.order(:observed_on)
      prior_actions = @case.case_actions.where.not(status: :cancelled).order(:created_at)
      ActionDrafts::Complaint.call(
        case_record: @case,
        observations: observations,
        rule_result: @rule_result,
        prior_actions: prior_actions
      )
    when :rti
      ActionDrafts::RtiRequest.call(
        case_record: @case,
        information_requested: ""
      )
    else
      nil
    end
  end

  def action_params
    params.require(:case_action).permit(
      :action_type, :status, :recommended_on, :taken_on, :outcome, :notes, :action_resource_id
    )
  end

  def update_params
    params.require(:case_action).permit(:status, :taken_on, :outcome, :notes)
  end
end
