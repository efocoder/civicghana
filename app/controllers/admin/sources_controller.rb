module Admin
  class SourcesController < CatalogController
    private
    def resource_class = Source
    def resource_title = "Sources"
    def form_fields = %i[title publisher url authority_type authority_level provision summary published_at effective_from effective_to last_verified_at last_checked_at http_status review_due_at review_required content_hash active]
  end
end
