module Admin
  class AgenciesController < CatalogController
    private
    def resource_class = Institution
    def resource_title = "Agencies"
    def form_fields = %i[country_id name slug short_name description website_url active]
  end
end
