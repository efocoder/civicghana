module Admin
  class AiDiagnosticsController < BaseController
    def show
      @diagnostic = Ai::Diagnostics.latest
      @provider = Ai::ProviderRegistry.fetch
    end
  end
end
