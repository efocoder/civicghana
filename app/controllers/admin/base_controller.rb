module Admin
  class BaseController < ApplicationController
    before_action :authenticate_admin!

    layout "admin"

    private

    def authenticate_admin!
      authenticate_or_request_with_http_basic("CivicRoute Admin") do |username, password|
        configured_username = ENV["ADMIN_USERNAME"].presence || Rails.application.credentials.dig(:admin, :username).to_s
        configured_password = ENV["ADMIN_PASSWORD"].presence || Rails.application.credentials.dig(:admin, :password).to_s

        configured_username.present? && configured_password.present? &&
          ActiveSupport::SecurityUtils.secure_compare(username, configured_username) &&
          ActiveSupport::SecurityUtils.secure_compare(password, configured_password)
      end
    end
  end
end
