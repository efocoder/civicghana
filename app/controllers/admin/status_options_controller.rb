module Admin
  class StatusOptionsController < CatalogController
    private
    def resource_class = PortalStatus
    def resource_title = "Status Options"
    def form_fields = %i[public_service_id name code position active]
  end
end
