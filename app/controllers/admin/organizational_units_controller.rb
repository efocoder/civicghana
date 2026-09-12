module Admin
  class OrganizationalUnitsController < CatalogController
    private
    def resource_class = OrganizationalUnit
    def resource_title = "Organizational Units"
    def form_fields = %i[institution_id name code description position active]
  end
end
