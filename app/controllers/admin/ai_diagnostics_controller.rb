module Admin
  class AiDiagnosticsController < BaseController
    def show
      @diagnostic = Ai::Diagnostics.latest
    end
  end
end
