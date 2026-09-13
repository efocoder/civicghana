module Admin
  class CatalogController < BaseController
    before_action :set_record, only: %i[edit update destroy]

    def index
      @records = resource_class.order(created_at: :desc)
    end

    def new
      @record = resource_class.new
    end

    def create
      @record = resource_class.new(resource_params)
      if @record.save
        redirect_to collection_path, notice: "Configuration saved."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit; end

    def update
      if @record.update(resource_params)
        redirect_to collection_path, notice: "Configuration updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @record.destroy
      redirect_to collection_path, notice: "Configuration removed."
    end

    helper_method :resource_class, :resource_title, :form_fields, :field_options, :collection_path

    private

    def set_record
      @record = resource_class.find(params[:id])
    end

    def resource_params
      params.require(resource_class.model_name.param_key).permit(*form_fields)
    end

    def field_options(attribute)
      association = resource_class.reflect_on_association(attribute.to_s.delete_suffix("_id").to_sym)
      return association.klass.order(:name).map { |record| [ record.name, record.id ] } if association

      enum = resource_class.defined_enums[attribute.to_s]
      enum&.keys&.map { |value| [ value.humanize, value ] }
    end

    def collection_path
      public_send("admin_#{controller_name}_path")
    end
  end
end
