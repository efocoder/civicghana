class CaseObservationsController < ApplicationController
  before_action :load_case

  def new
    @observation = @case.case_observations.build(observed_on: Date.current)
    @tracking_steps = @case.public_service.process_steps.active
    @portal_statuses = @case.public_service.portal_statuses.active
  end

  def create
    @observation = @case.case_observations.build(observation_params)
    @tracking_steps = @case.public_service.process_steps.active
    @portal_statuses = @case.public_service.portal_statuses.active
    milestones = submitted_milestones

    milestones.each do |step_id, status|
      @observation.case_milestone_observations.build(process_step_id: step_id, status: status)
    end

    CaseObservation.transaction do
      if @observation.portal? && milestones.empty?
        @observation.errors.add(:base, "at least one portal milestone status is required")
        raise ActiveRecord::Rollback
      end

      @observation.save!
    end

    if @observation.persisted?
      redirect_to @case
    else
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  private

  def load_case
    @case = Case.includes(:public_service).find(params[:case_id])
  end

  def observation_params
    params.require(:case_observation).permit(
      :observation_type, :observed_on, :overall_status,
      :summary, :progress_claim, :reported_process_step_id
    )
  end

  def submitted_milestones
    allowed_ids = @tracking_steps.map { |step| step.id.to_s }

    params.fetch(:milestones, {}).to_unsafe_h.filter_map do |step_id, status|
      next if status.blank? || !allowed_ids.include?(step_id.to_s)
      next unless @portal_statuses.any? { |record| record.name == status || record.code == status }

      [ step_id, status ]
    end
  end
end
