module Admin
  class ServiceVariantsController < CatalogController
    private
    def resource_class = ServiceVariant
    def resource_title = "Service Variants"
    def form_fields = %i[public_service_id name slug description position active]
  end
end
