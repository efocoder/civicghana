module Admin
  class ProcessStepsController < CatalogController
    private
    def resource_class = ProcessStep
    def resource_title = "Process Steps"
    def form_fields = %i[public_service_id source_id name description position active]
  end
end
