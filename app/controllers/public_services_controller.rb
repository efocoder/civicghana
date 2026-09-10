class PublicServicesController < ApplicationController
  def index
    @public_services = PublicService.includes(institution: :country)
      .joins(institution: :country)
      .where(active: true, institutions: { active: true }, countries: { active: true })
      .order("countries.name", "institutions.name", "public_services.name")
  end

  def show
    @public_service = PublicService.includes(:process_steps, :action_paths, institution: :country)
      .find_by!(slug: params[:slug], active: true)
    @duration_rule = ServiceRules::Resolver.call(
      public_service: @public_service,
      rule_type: :expected_duration_days
    )
  rescue ServiceRules::Resolver::NotFound
    @duration_rule = nil
  end
end
