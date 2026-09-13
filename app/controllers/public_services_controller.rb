class PublicServicesController < ApplicationController
  def index
    @agencies = Institution.active.order(:name)
    @units = OrganizationalUnit.active.ordered
    @public_services = PublicService.includes(:organizational_unit, :catalog_translations, institution: [ :catalog_translations, :country ])
      .joins(institution: :country)
      .where(active: true, institutions: { active: true }, countries: { active: true })
    @public_services = @public_services.where(institution_id: params[:agency_id]) if params[:agency_id].present?
    @public_services = @public_services.where(organizational_unit_id: params[:unit_id]) if params[:unit_id].present?
    if params[:q].present?
      query = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].strip)}%"
      @public_services = @public_services.where("public_services.name ILIKE ? OR public_services.description ILIKE ?", query, query)
    end
    @public_services = @public_services.order(
      Arel.sql("CASE WHEN public_services.slug = 'official-consolidated-search' THEN 0 ELSE 1 END"),
      Arel.sql("CASE WHEN public_services.support_level = 'trackable' THEN 0 WHEN public_services.support_level = 'guided' THEN 1 ELSE 2 END"),
      "countries.name", "institutions.name", "public_services.name"
    )
  end

  def show
    @public_service = PublicService.includes(:organizational_unit, :service_variants, :requirements, :service_fees, :catalog_translations, :action_paths, :sources, :action_resources, process_steps: :catalog_translations, institution: [ :catalog_translations, :country ])
      .find_by!(slug: params[:slug], active: true)
    @duration_rule = ServiceRules::Resolver.call(
      public_service: @public_service,
      rule_type: %w[deed-registration registration-of-title].include?(@public_service.slug) ? :service_charter_turnaround : :expected_duration_days
    )
  rescue ServiceRules::Resolver::NotFound
    @duration_rule = nil
  end
end
