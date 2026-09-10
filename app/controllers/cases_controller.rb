class CasesController < ApplicationController
  def new
    @case = Case.new
    @public_service = PublicService.find_by!(slug: params[:service_slug] || "official-consolidated-search")
    @tracking_steps = @public_service.process_steps.where("sequence >= 4").order(:sequence)
  end

  def create
    @case = Case.new(case_params)
    @public_service = PublicService.find_by(id: case_params[:public_service_id], active: true)
    unless @public_service
      @case.errors.add(:public_service, "must be a valid active service")
      @tracking_steps = []
      return render :new, status: :unprocessable_entity
    end

    @case.public_service = @public_service
    @tracking_steps = @public_service.process_steps.where("sequence >= 4").order(:sequence)
    @observation = @case.case_observations.build(observation_params)

    begin
      Case.transaction do
        @case.save!
        @observation.save!

        submitted_milestones.each do |step_id, status|
          @observation.case_milestone_observations.create!(
            process_step_id: step_id,
            status: status
          )
        end
      end
      redirect_to @case
    rescue ActiveRecord::RecordInvalid
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @case = Case.includes(:public_service, case_observations: { case_milestone_observations: :process_step }).find(params[:id])
    @observation = @case.case_observations.first!
    @milestones = @observation&.case_milestone_observations&.includes(:process_step)&.sort_by { |m| m.process_step.sequence } || []
    assessment = CaseAssessment::Evaluate.call(
      case_record: @case,
      assessment_date: @observation.observed_on
    )
    @lifecycle = assessment[:lifecycle]
    @rule_result = assessment[:rule]
  end

  private

  def case_params
    params.require(:case).permit(:public_service_id, :application_completed_on, :payment_date, :portal_created_on, :region)
  end

  def observation_params
    params.fetch(:case_observation, {}).permit(:observed_on, :overall_status).merge(observation_type: :portal)
  end

  def submitted_milestones
    milestone_params = params.fetch(:milestones, {}).to_h
    allowed_ids = @tracking_steps.map { |step| step.id.to_s }

    milestone_params.filter_map do |step_id, status|
      next if status.blank? || !allowed_ids.include?(step_id.to_s)

      [ step_id, status ]
    end
  end
end
