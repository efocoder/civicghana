module Admin
  class SourceChunksController < CatalogController
    private
    def resource_class = SourceChunk
    def resource_title = "Source Chunks"
    def form_fields = %i[source_id public_service_id section_label heading provision content position page_number active]
  end
end
