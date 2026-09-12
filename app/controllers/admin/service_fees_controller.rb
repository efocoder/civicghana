module Admin
  class ServiceFeesController < CatalogController
    private
    def resource_class = ServiceFee
    def resource_title = "Service Fees"
    def form_fields = %i[public_service_id service_variant_id source_id name amount currency calculation_type description effective_from effective_to active]
  end
end
