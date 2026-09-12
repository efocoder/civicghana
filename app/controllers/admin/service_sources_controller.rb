module Admin
  class ServiceSourcesController < CatalogController
    private
    def resource_class = ServiceSource
    def resource_title = "Service Sources"
    def form_fields = %i[public_service_id source_id purpose primary]
  end
end
