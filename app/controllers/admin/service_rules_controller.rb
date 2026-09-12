module Admin
  class ServiceRulesController < CatalogController
    private
    def resource_class = ServiceRule
    def resource_title = "Service Rules"
    def form_fields = %i[public_service_id source_id name rule_type duration_value duration_unit anchor_event description effective_from effective_to verified_at active]
  end
end
