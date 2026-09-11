class ApplicationController < ActionController::Base
  around_action :switch_locale

  private

  def switch_locale(&action)
    locale = extract_locale
    I18n.with_locale(locale, &action)
  end

  def extract_locale
    if params[:locale].present? && I18n.available_locales.include?(params[:locale].to_sym)
      cookies[:locale] = { value: params[:locale], expires: 1.year.from_now }
      params[:locale].to_sym
    elsif cookies[:locale].present? && I18n.available_locales.include?(cookies[:locale].to_sym)
      cookies[:locale].to_sym
    else
      I18n.default_locale
    end
  end

  def default_url_options
    { locale: I18n.locale == I18n.default_locale ? nil : I18n.locale }
  end
end
