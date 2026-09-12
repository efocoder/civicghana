module Admin
  class ActionResourcesController < CatalogController
    private
    def resource_class = ActionResource
    def resource_title = "Action Resources"
    def form_fields = %i[institution_id public_service_id source_id name resource_type purpose url email phone instructions position last_verified_at active]
  end
end
