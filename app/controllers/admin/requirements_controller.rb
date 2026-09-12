module Admin
  class RequirementsController < CatalogController
    private
    def resource_class = Requirement
    def resource_title = "Requirements"
    def form_fields = %i[public_service_id service_variant_id source_id category title description position mandatory active]
  end
end
