class CasesController < ApplicationController
  def new
    @case = Case.new
    services = PublicService.includes(:catalog_translations, process_steps: :catalog_translations, institution: [ :catalog_translations, :country ])
      .where(active: true, case_enabled: true, support_level: "trackable")
    @public_service = if params[:service_slug].present?
      services.find_by!(slug: params[:service_slug])
    else
      services.order(Arel.sql("CASE WHEN slug = 'official-consolidated-search' THEN 0 ELSE 1 END"), tracks_portal_milestones: :desc, name: :asc).first!
    end
    @tracking_steps = tracking_steps_for(@public_service)
    @regions = @public_service.institution.country.regions.active.order(:name)
    @portal_statuses = @public_service.portal_statuses.active
  end

  def create
    @case = Case.new(case_params)
    @public_service = PublicService.find_by(id: case_params[:public_service_id], active: true, case_enabled: true, support_level: "trackable")
    unless @public_service
      @case.errors.add(:public_service, "must be a valid active service")
      @tracking_steps = []
      @regions = []
      @portal_statuses = []
      return render :new, status: :unprocessable_entity
    end

    @case.public_service = @public_service
    @tracking_steps = tracking_steps_for(@public_service)
    @regions = @public_service.institution.country.regions.active.order(:name)
    @portal_statuses = @public_service.portal_statuses.active
    @observation = @case.case_observations.build(observation_params) if @public_service.tracks_portal_milestones?
    submitted_milestones.each { |step_id, status| @observation.case_milestone_observations.build(process_step_id: step_id, status: status) }

    begin
      Case.transaction do
        if @public_service.tracks_portal_milestones? && submitted_milestones.empty?
          @observation.errors.add(:base, "at least one portal milestone status is required")
          raise ActiveRecord::Rollback
        end

        @case.save!
        @observation&.save!
      end
      if @case.persisted?
        redirect_to @case
      else
        render :new, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordInvalid
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @case = Case.includes(:public_service, case_observations: { case_milestone_observations: :process_step }).find(params[:id])
    @observations = @case.case_observations.includes(:case_milestone_observations, :reported_process_step).order(:observed_on, :created_at)
    @latest_portal = @observations.select(&:portal?).last
    @milestones = @latest_portal&.case_milestone_observations&.includes(:process_step)&.sort_by { |m| m.process_step.sequence } || []

    assessment = CaseAssessment::Evaluate.call(
      case_record: @case,
      assessment_date: @latest_portal&.observed_on || Date.current
    )
    @lifecycle = assessment[:lifecycle]
    @rule_result = assessment[:rule]

    @evidence_comparison = EvidenceAssessment::Compare.call(case_record: @case)
    @evidence_counts = {
      total: @observations.size,
      portal: @observations.count(&:portal?),
      non_portal: @observations.count { |o| !o.portal? }
    }

    @action_recommendation = ActionRecommendation::Evaluate.call(
      case_record: @case,
      rule_result: @rule_result,
      evidence_comparison: @evidence_comparison,
      information_need: params[:need]
    )
    @selected_need = params[:need].presence
    @existing_actions = @case.case_actions.includes(:action_resource).order(:created_at)
  end

  private

  def case_params
    params.require(:case).permit(:public_service_id, :application_completed_on, :payment_date, :portal_created_on, :region)
  end

  def observation_params
    params.fetch(:case_observation, {}).permit(:observed_on, :overall_status).merge(observation_type: :portal)
  end

  def tracking_steps_for(service)
    service.tracks_portal_milestones? ? service.process_steps.active : ProcessStep.none
  end

  def submitted_milestones
    milestone_params = params.fetch(:milestones, {}).to_unsafe_h
    allowed_ids = @tracking_steps.map { |step| step.id.to_s }

    milestone_params.filter_map do |step_id, status|
      next if status.blank? || !allowed_ids.include?(step_id.to_s)
      next unless @portal_statuses.any? { |record| record.name == status || record.code == status }

      [ step_id, status ]
    end
  end
end
