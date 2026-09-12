module Admin
  class PublicServicesController < CatalogController
    private
    def resource_class = PublicService
    def resource_title = "Public Services"
    def form_fields = %i[institution_id organizational_unit_id name slug description service_code service_category support_level active case_enabled tracks_portal_milestones requires_region]
  end
end
