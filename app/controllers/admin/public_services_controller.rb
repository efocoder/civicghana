module Admin
  class PublicServicesController < CatalogController
    private
    def resource_class = PublicService
    def resource_title = "Public Services"
    def form_fields = %i[institution_id name slug description service_code service_category active case_enabled]
  end
end
